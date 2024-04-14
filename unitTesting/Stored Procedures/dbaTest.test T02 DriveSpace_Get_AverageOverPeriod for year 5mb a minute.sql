SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbaTest].[test T02 DriveSpace_Get_AverageOverPeriod for year 5mb a minute]
AS
BEGIN
    /*Cleanup*/
    DROP TABLE IF EXISTS #Expected_Results;
    DROP TABLE IF EXISTS #Actual_Results;

    /*Create fake table*/
    EXEC tSQLt.FakeTable @TableName = N'DriveSpaceHistory',
                         @SchemaName = N'dba',
                         @Identity = 1;

    /*insert sample data*/
    DECLARE @StartDate DATETIME = DATEADD(YEAR, -1, GETDATE()),
            @EndDate DATETIME = GETDATE(),
            @EveryXMinutes INT = 15,
            @GB_Minute DECIMAL(36, 8) = CONVERT(DECIMAL(36, 8), 5) / 1024,
            @DriveName NVARCHAR(30) = N'C Drive Test',
            @DriveLetter NVARCHAR(2) = N'C',
            @MaxSize DECIMAL(36, 8) = 500,
            @InitialSize DECIMAL(36, 8) = 1;
    DECLARE @InitialFree DECIMAL(36, 8) = (@MaxSize - @InitialSize),
            @InitialUsedPrec DECIMAL(36, 8) = @InitialSize / @MaxSize;


    INSERT INTO dba.DriveSpaceHistory
    (
        Drive,
        Drive_Letter,
        DriveTotalSpace_GB,
        DriveFreeSpace_GB,
        Drive_UsedPrecentage,
        CapturedDateTime
    )
    EXEC dbaTest_Load.Insert_DriveSpaceHistory @Drive = @DriveName,
                                               @DriveLetter = @DriveLetter,
                                               @DriveTotalSpace_GB = @MaxSize,
                                               @DriveFreeSpace_GB = @InitialFree,
                                               @Drive_UsedPrecentage = @InitialUsedPrec,
                                               @CapturedDateTime = @StartDate;

    DECLARE @InsertDate DATETIME = DATEADD(MINUTE, @EveryXMinutes, @StartDate),
            @AmountUsed DECIMAL(36, 8) = @InitialSize + (@GB_Minute * @EveryXMinutes);

    DECLARE @InsertFreeSpace DECIMAL(36, 8) = (@MaxSize - @AmountUsed);
    DECLARE @InsertUsedPrecentage DECIMAL(36, 8) = @InsertFreeSpace / @MaxSize;

    WHILE (@InsertDate < @EndDate)
    BEGIN

        INSERT INTO dba.DriveSpaceHistory
        (
            Drive,
            Drive_Letter,
            DriveTotalSpace_GB,
            DriveFreeSpace_GB,
            Drive_UsedPrecentage,
            CapturedDateTime
        )
        EXEC dbaTest_Load.Insert_DriveSpaceHistory @Drive = @DriveName,
                                                   @DriveLetter = @DriveLetter,
                                                   @DriveTotalSpace_GB = @MaxSize,
                                                   @DriveFreeSpace_GB = @InsertFreeSpace,
                                                   @Drive_UsedPrecentage = @InsertUsedPrecentage,
                                                   @CapturedDateTime = @InsertDate;

        SELECT @AmountUsed = @AmountUsed + (@GB_Minute * @EveryXMinutes),
               @InsertDate = DATEADD(MINUTE, @EveryXMinutes, @InsertDate);
        SET @InsertFreeSpace = (@MaxSize - @AmountUsed);
        SET @InsertUsedPrecentage = @InsertFreeSpace / @MaxSize;
    END;


    /*expected*/
    SELECT @DriveName AS Drive,
           @DriveLetter AS Drive_Letter,
           (@GB_Minute / 60) AS Sum_Change_GBaSecond,
           @GB_Minute AS Change_GBaMinute,
           (@GB_Minute * 60) AS Change_GBaHour
    INTO #Expected_Results;

    /*Assert*/
    CREATE TABLE #Actual_Results
    (
        Drive NVARCHAR(260),
        Drive_Letter NVARCHAR(10),
        Sum_Change_GBaSecond DECIMAL(36, 8),
        Change_GBaMinute DECIMAL(36, 8),
        Change_GBaHour DECIMAL(36, 8)
    );

    INSERT INTO #Actual_Results
	SELECT * FROM dba.DriveSpace_Get_AverageOverPeriod(@StartDate , @EndDate, @DriveLetter);

    DECLARE @actualResult_Drive NVARCHAR(260),
            @actualResult_Drive_Letter NVARCHAR(10),
            @actualResult_Sum_Change_GBaSecond DECIMAL(36, 8),
            @actualResult_Change_GBaMinute DECIMAL(36, 8),
            @actualResult_Change_GBaHour DECIMAL(36, 8);


    DECLARE @expectedResult_Drive NVARCHAR(260),
            @expectedResult_Drive_Letter NVARCHAR(10),
            @expectedResult_Sum_Change_GBaSecond DECIMAL(36, 8),
            @expectedResult_Change_GBaMinute DECIMAL(36, 8),
            @expectedResult_Change_GBaHour DECIMAL(36, 8);


    SELECT @actualResult_Drive = Drive,
           @actualResult_Drive_Letter = Drive_Letter,
           @actualResult_Sum_Change_GBaSecond = Sum_Change_GBaSecond,
           @actualResult_Change_GBaMinute = Change_GBaMinute,
           @actualResult_Change_GBaHour = Change_GBaHour
    FROM #Actual_Results;

    SELECT @expectedResult_Drive = Drive,
           @expectedResult_Drive_Letter = Drive_Letter,
           @expectedResult_Sum_Change_GBaSecond = Sum_Change_GBaSecond,
           @expectedResult_Change_GBaMinute = Change_GBaMinute,
           @expectedResult_Change_GBaHour = Change_GBaHour
    FROM #Expected_Results;

    DECLARE @failureMessage NVARCHAR(400),
            @MaxDiff DECIMAL(38, 12) = 0.000001;
    EXEC tSQLt.AssertEquals @Expected = @expectedResult_Drive,
                            @Actual = @actualResult_Drive,
                            @Message = N'Drive name did not match';
    EXEC tSQLt.AssertEquals @Expected = @expectedResult_Drive_Letter,
                            @Actual = @actualResult_Drive_Letter,
                            @Message = N'Drive letter did not match';
    IF ABS(@actualResult_Sum_Change_GBaSecond - @expectedResult_Sum_Change_GBaSecond) > @MaxDiff
    BEGIN
        PRINT CONVERT(NVARCHAR(20), ABS(@actualResult_Sum_Change_GBaSecond - @expectedResult_Sum_Change_GBaSecond));
        SET @failureMessage
            = CONCAT(
                        'Assert failed on @actualResult_Sum_Change_GBaSecond and @expectedResult_Sum_Change_GBaSecond. ',
                        'Difference max of ',
                        CONVERT(NVARCHAR(20), @MaxDiff),
                        ' excided. ',
                        CONVERT(
                                   NVARCHAR(20),
                                   ABS(@actualResult_Sum_Change_GBaSecond - @expectedResult_Sum_Change_GBaSecond)
                               )
                    );
        EXEC tSQLt.Fail @Message0 = @failureMessage;
    END;
    IF ABS(@actualResult_Change_GBaMinute - @expectedResult_Change_GBaMinute) > @MaxDiff
    BEGIN
        PRINT CONVERT(NVARCHAR(20), ABS(@actualResult_Change_GBaMinute - @expectedResult_Change_GBaMinute));
        SET @failureMessage
            = CONCAT(
                        'Assert failed on @@actualResult_Change_GBaMinute and @expectedResult_Change_GBaMinute. ',
                        'Difference max of ',
                        CONVERT(NVARCHAR(20), @MaxDiff),
                        ' excided. ',
                        CONVERT(NVARCHAR(20), ABS(@actualResult_Change_GBaMinute - @expectedResult_Change_GBaMinute))
                    );
        EXEC tSQLt.Fail @Message0 = @failureMessage;
    END;
    IF ABS(@actualResult_Change_GBaHour - @expectedResult_Change_GBaHour) > @MaxDiff
    BEGIN
        PRINT CONVERT(NVARCHAR(20), ABS(@actualResult_Change_GBaHour - @expectedResult_Change_GBaHour));
        SET @failureMessage
            = CONCAT(
                        'Assert failed on @actualResult_Change_GBaHour and @expectedResult_Change_GBaHour. ',
                        'Difference max of ',
                        CONVERT(NVARCHAR(20), @MaxDiff),
                        ' excided. ',
                        CONVERT(NVARCHAR(20), ABS(@actualResult_Change_GBaHour - @expectedResult_Change_GBaHour))
                    );
        EXEC tSQLt.Fail @Message0 = @failureMessage;
    END;

END;

GO
