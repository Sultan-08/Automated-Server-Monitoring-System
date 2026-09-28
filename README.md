# Automated Server Monitoring & Alert System 🚨.

A Linux-based server monitoring and alert system developed using Bash Shell Scripting and standard Linux utilities.

The system monitors important server resources and services, records monitoring information, sends email alerts when configured thresholds are exceeded, and supports automated execution using Cron.

## Features -

- CPU usage monitoring.
- Memory usage monitoring.
- Root disk usage monitoring.
- Linux service monitoring.
- Automatic service restart attempt.
- Network connectivity monitoring.
- Email alerts using Postfix and Mailutils.
- Centralized system and alert logging.
- Interactive terminal dashboard.
- Automated execution using Cron.
- Configurable monitoring thresholds.
- Installation script for required packages.

## Technologies -

- Ubuntu/Linux.
- Bash Shell Scripting.
- Postfix.
- Mailutils.
- Cron.
- Whiptail.
- Standard Linux utilities such as:
  - `top`
  - `free`
  - `df`
  - `systemctl`
  - `ping`
  - `awk`
  - `sed`

## Project Structure -

```text
Automated Server Monitoring System/
├── monitor.sh
├── dashboard.sh
├── install.sh
├── config/
│   └── threshold.conf
├── modules/
│   ├── cpu_monitor.sh
│   ├── memory_monitor.sh
│   ├── disk_monitor.sh
│   ├── service_monitor.sh
│   ├── network_monitor.sh
│   ├── alert.sh
│   └── logger.sh
├── logs/
├── reports/
├── .gitignore
├── README.md
└── LICENSE
```

## Project Dashboard -
<img width="811" height="581" alt="Screenshot from 2026-09-19 20-25-09" src="https://github.com/user-attachments/assets/19f66ed5-d4e0-444b-bfdb-bd4fe3e710f3" />

## Learning Outcomes -

* Linux Administration.
* Shell Scripting.
* Automation.
* Cron Jobs.
* Log Management.
* System Monitoring.
* DevOps Fundamentals.

## Future Enhancements -

* Docker Monitoring.
* Multi-Server Monitoring.
* Web Dashboard.
* Grafana Integration.
* Cloud Monitoring.

## License -

MIT License.

## Author -

[Sultan Mulani](https://github.com/Sultan-08)
