SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE       PROCEDURE [dbaTest].[test T03 DriveSpace_Get_AverageOverPeriod For date range, return Average for all 5 drives]
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
	DECLARE             @EndDate DATETIME = GETDATE();

    DECLARE @StartDate DATETIME = DATEADD(YEAR, -1, @EndDate),
            @AWeekAgo DATETIME =  DATEADD(WEEK, -1, @EndDate);

	DECLARE @TestData TABLE(
		DriveLetter NVARCHAR(2),
		DriveName NVARCHAR(30),
		MaxSize DECIMAL(36,8),
		InitialSize DECIMAL(36,8),
		CreateEntryEveryXMinutes INT,
		GB_ConsumedAMinute DECIMAL(36,8),
		FirstEntryDate DATETIME,
		LastEntryDate DATETIME,
		ExpectedNumberOfRows AS  (DATEDIFF(MINUTE,FirstEntryDate, LastEntryDate)/ CreateEntryEveryXMinutes),
		/*---------------------------*/
		InsertDate datetime,
		InsertFreeSpace  DECIMAL(36,8),
		InsertUsedPrecentage  DECIMAL(36,8)
	);
	
INSERT INTO @TestData(DriveLetter, DriveName, MaxSize, InitialSize, CreateEntryEveryXMinutes, GB_ConsumedAMinute, FirstEntryDate, LastEntryDate, InsertDate, InsertFreeSpace, InsertUsedPrecentage)
VALUES(N'C', N'Main Drive', 30, 28, 90, 0, @StartDate, @EndDate, @StartDate, 30-28, 28.0/30 );

INSERT INTO @TestData(DriveLetter, DriveName, MaxSize, InitialSize, CreateEntryEveryXMinutes, GB_ConsumedAMinute, FirstEntryDate, LastEntryDate, InsertDate, InsertFreeSpace, InsertUsedPrecentage)
VALUES(N'T', N'TempDB Drive', 700, 200, 90, .002, @StartDate, @EndDate, @StartDate, 700-200, 200.0/700);

INSERT INTO @TestData(DriveLetter, DriveName, MaxSize, InitialSize, CreateEntryEveryXMinutes, GB_ConsumedAMinute, FirstEntryDate, LastEntryDate, InsertDate, InsertFreeSpace, InsertUsedPrecentage)
VALUES(N'L', N'Log Drive', 500, 300, 90, .0014, @StartDate, @EndDate, @StartDate, 500-300, 300.0/500);

INSERT INTO @TestData(DriveLetter, DriveName, MaxSize, InitialSize, CreateEntryEveryXMinutes, GB_ConsumedAMinute, FirstEntryDate, LastEntryDate, InsertDate, InsertFreeSpace, InsertUsedPrecentage)
VALUES(N'E', N'Data 01 Drive', 300, 150, 90, .0010, @StartDate, @EndDate, @StartDate, 300-150, 150/300);

INSERT INTO @TestData(DriveLetter, DriveName, MaxSize, InitialSize, CreateEntryEveryXMinutes, GB_ConsumedAMinute, FirstEntryDate, LastEntryDate, InsertDate, InsertFreeSpace, InsertUsedPrecentage)
VALUES(N'F', N'Data 02 Drive', 700, 175, 90, .0022, @StartDate, @EndDate, @StartDate, 700-175, 175/700 );

	DECLARE 
	@InsertDriveName NVARCHAR(30),
    @InsertDriveLetter NVARCHAR(2),
    @InsertMaxSize DECIMAL(36,8),
    @InsertFreeSpace DECIMAL(36,8),
    @InsertUsedPrecentage DECIMAL(36,8),
    @InsertDate DATETIME;

    WHILE EXISTS(SELECT 1 FROM @TestData td 
							OUTER APPLY (SELECT dh.Drive_Letter, COUNT(*) NumberEntries FROM dba.DriveSpaceHistory dh WHERE td.DriveLetter = dh.Drive_Letter GROUP BY dh.Drive_Letter) AS RowCounter 
						WHERE td.ExpectedNumberOfRows > ISNULL(RowCounter.NumberEntries, 0) )
    BEGIN
		SELECT @InsertDriveLetter = td.DriveLetter
		FROM @TestData td
			OUTER APPLY
		(
			SELECT dh.Drive_Letter,
				   COUNT(*) NumberEntries
			FROM dba.DriveSpaceHistory dh
			WHERE td.DriveLetter = dh.Drive_Letter
			GROUP BY dh.Drive_Letter
		) AS RowCounter
		WHERE td.ExpectedNumberOfRows > ISNULL(RowCounter.NumberEntries, 0);

		SELECT 
		@InsertDriveName = td.DriveName,
		@InsertMaxSize = td.MaxSize,
		@InsertFreeSpace = td.InsertFreeSpace,
		@InsertUsedPrecentage = td.InsertUsedPrecentage,
		@InsertDate = td.InsertDate
		FROM @TestData td
		WHERE td.DriveLetter = @InsertDriveLetter;
		
        EXEC dbaTest_Load.Insert_DriveSpaceHistory @Drive = @InsertDriveName,
                                                   @DriveLetter = @InsertDriveLetter,
                                                   @DriveTotalSpace_GB = @InsertMaxSize,
                                                   @DriveFreeSpace_GB = @InsertFreeSpace,
                                                   @Drive_UsedPrecentage = @InsertUsedPrecentage,
                                                   @CapturedDateTime = @InsertDate;

		IF EXISTS(SELECT 1 FROM @TestData td 
							OUTER APPLY (SELECT dh.Drive_Letter, COUNT(*) NumberEntries FROM dba.DriveSpaceHistory dh WHERE td.DriveLetter = dh.Drive_Letter GROUP BY dh.Drive_Letter) AS RowCounter  
						WHERE td.DriveLetter = @InsertDriveLetter AND td.ExpectedNumberOfRows > ISNULL(RowCounter.NumberEntries, 0) )
		BEGIN
			UPDATE td
			SET 
				td.InsertFreeSpace = td.InsertFreeSpace - (td.CreateEntryEveryXMinutes * td.GB_ConsumedAMinute), 
				td.InsertUsedPrecentage = (MaxSize - (td.InsertFreeSpace - (td.CreateEntryEveryXMinutes * td.GB_ConsumedAMinute)))
										 / MaxSize ,
				td.InsertDate = DATEADD(MINUTE,td.CreateEntryEveryXMinutes, td.InsertDate)
			FROM @TestData td 
			WHERE td.DriveLetter = @InsertDriveLetter
		END
    END;


    /*expected*/
    SELECT td.DriveName AS Drive,
           td.DriveLetter AS Drive_Letter,
           (td.GB_ConsumedAMinute/ 60) AS Sum_Change_GBaSecond,
           td.GB_ConsumedAMinute AS Change_GBaMinute,
           (td.GB_ConsumedAMinute * 60) AS Change_GBaHour
    INTO #Expected_Results
	FROM @TestData td;

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
	SELECT * FROM dba.DriveSpace_Get_AverageOverPeriod(@StartDate , @EndDate, DEFAULT);

		SELECT * FROM #Actual_Results;
		 SELECT *,
          (DriveTotalSpace_GB - DriveFreeSpace_GB) AS UsedSpace_GB
   FROM master.dba.DriveSpaceHistory d
	/*PREFORM VALIDATIONS*/
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

    SELECT TOP (1) @expectedResult_Drive = Drive,
           @expectedResult_Drive_Letter = Drive_Letter,
           @expectedResult_Sum_Change_GBaSecond = Sum_Change_GBaSecond,
           @expectedResult_Change_GBaMinute = Change_GBaMinute,
           @expectedResult_Change_GBaHour = Change_GBaHour
    FROM #Expected_Results;
	
    SELECT @actualResult_Drive = Drive,
           @actualResult_Drive_Letter = Drive_Letter,
           @actualResult_Sum_Change_GBaSecond = Sum_Change_GBaSecond,
           @actualResult_Change_GBaMinute = Change_GBaMinute,
           @actualResult_Change_GBaHour = Change_GBaHour
    FROM #Actual_Results
	WHERE @expectedResult_Drive = Drive;


	select '#Expected_Results'
	SELECT * FROM #Expected_Results;
	select '#Actual_Results'
	SELECT * FROM #Actual_Results;

    DECLARE @failureMessage NVARCHAR(400),
            @MaxDiff DECIMAL(38, 12) = 0.0001;

	WHILE (@expectedResult_Drive_Letter IS NOT NULL)
	BEGIN 
		

		EXEC tSQLt.AssertEquals @Expected = @expectedResult_Drive,
								@Actual = @actualResult_Drive,
								@Message = N'Drive name did not match';
		EXEC tSQLt.AssertEquals @Expected = @expectedResult_Drive_Letter,
								@Actual = @actualResult_Drive_Letter,
								@Message = N'Drive letter did not match';
			PRINT'1'
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
			PRINT'2'
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
			PRINT'3'
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

		DELETE ER
		FROM #Expected_Results er
		WHERE er.Drive_Letter = @expectedResult_Drive_Letter;
		
		select @@ROWCOUNT

		SELECT @expectedResult_Drive = NULL,
			   @expectedResult_Drive_Letter = NULL,
			   @expectedResult_Sum_Change_GBaSecond = NULL,
			   @expectedResult_Change_GBaMinute = NULL,
			   @expectedResult_Change_GBaHour = NULL;

		SELECT TOP (1) @expectedResult_Drive = Drive,
			   @expectedResult_Drive_Letter = Drive_Letter,
			   @expectedResult_Sum_Change_GBaSecond = Sum_Change_GBaSecond,
			   @expectedResult_Change_GBaMinute = Change_GBaMinute,
			   @expectedResult_Change_GBaHour = Change_GBaHour
		FROM #Expected_Results;
		SELECT @actualResult_Drive = Drive,
			   @actualResult_Drive_Letter = Drive_Letter,
			   @actualResult_Sum_Change_GBaSecond = Sum_Change_GBaSecond,
			   @actualResult_Change_GBaMinute = Change_GBaMinute,
			   @actualResult_Change_GBaHour = Change_GBaHour
		FROM #Actual_Results
		WHERE @expectedResult_Drive = Drive;

	END

END;

GO
