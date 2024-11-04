# MSSQL DriveSpace
[![Project Status](https://img.shields.io/badge/status-active-brightgreen)]() [![License](https://img.shields.io/badge/license-MIT-blue)]()

## Overview
MSSQL DriveSpace is a SQL Server-based solution that monitors database drive space usage, providing insights to prevent storage bottlenecks and optimize performance.

This tool offers database administrators a straightforward way to track available drive space, predict storage needs, and set alerts based on customizable thresholds.


## Features
- **Real-Time Drive Monitoring**: Continuously monitors drive space and provides up-to-date information on usage.
- **Predictive Analysis**: Analyzes historical trends to forecast when storage might reach capacity.
- **Custom Alerts**: Enables administrators to set alerts for specified thresholds, ensuring proactive management of drive space.
- **Historical Data Views**: Provides detailed reports and views of storage trends over time, aiding in long-term planning.


## Installation
### Prerequisites
- SQL Server 2016 or later.
- Access to SQL Server Agent (for scheduled tasks).

### Setup Instructions
1. Clone the repository:
   ```shell
   git clone https://github.com/chris904apps/MSSQL_DriveSpace.git

Additional Details to come...

## Usage
### Running the Monitoring Script
- Set up the SQL Server Agent to execute the monitoring stored procedure every X minutes (configurable).

### Example Views and Reports
- View historical drive usage data to understand storage trends.
- Use the [predicted utilization] view to estimate future space needs.


## Developer Guide

### Code Structure
- `stored_procs/`: Contains stored procedures for data collection, alerting, and reporting.
- `views/`: SQL views for historical and predictive data analysis.

## Contribution Guidelines

- Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.
- Ensure tests cover new or updated functionality.
- For a list of current workitems see...

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.
