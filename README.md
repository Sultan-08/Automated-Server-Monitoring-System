# Automated Server Monitoring & Alert System

A Linux-based monitoring solution developed using Bash Shell Scripting.
The system continuously monitors CPU, Memory, Disk Usage, Services, and Network Connectivity, and sends Email Alerts when predefined thresholds are exceeded.

## Features

* CPU Usage Monitoring
* Memory Usage Monitoring
* Disk Usage Monitoring
* Service Health Monitoring
* Network Connectivity Monitoring
* Email Notifications
* Log Management
* Cron Job Automation
* Auto-Restart for Failed Services
* Terminal Dashboard

## Technologies Used

* Bash Shell Scripting
* Ubuntu/Linux
* Cron
* Mailutils
* Systemctl
* Awk, Sed, Grep
* Whiptail

## Project Structure

```text
ServerMonitoringSystem/
│
├── monitor.sh
├── dashboard.sh
├── install.sh
│
├── config/
├── modules/
├── logs/
├── reports/
└── README.md
```

## Installation

```bash
git clone https://github.com/your-username/Automated-Server-Monitoring-System.git

cd Automated-Server-Monitoring-System

chmod +x *.sh
chmod +x modules/*.sh

./install.sh
```

## Run Project

Start Monitoring:

```bash
./monitor.sh
```

Open Dashboard:

```bash
./dashboard.sh
```

## Configuration

Edit the threshold values in:

```bash
config/threshold.conf
```

Example:

```bash
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85
ADMIN_EMAIL=your-email@example.com
```

## Learning Outcomes

* Linux Administration
* Shell Scripting
* Automation
* Cron Jobs
* Log Management
* System Monitoring
* DevOps Fundamentals

## Future Enhancements

* Docker Monitoring
* Multi-Server Monitoring
* Web Dashboard
* Grafana Integration
* Cloud Monitoring

## License

MIT License

## Author

@Sultan-08
