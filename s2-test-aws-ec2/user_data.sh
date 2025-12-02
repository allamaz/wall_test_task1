#!/bin/bash
set -e
yum update -y
hostnamectl set-hostname ${hostname}
yum install -y \
    htop \
    vim \
    git \
    wget \
    curl \
    unzip \
    tree \
    jq \
    amazon-cloudwatch-agent \
    aws-cli

cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<'EOF'
{
  "metrics": {
    "namespace": "CustomEC2Metrics",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"},
          {"name": "cpu_usage_iowait", "rename": "CPU_IOWAIT", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          {"name": "used_percent", "rename": "DISK_USED", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": [
          {"name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/${hostname}",
            "log_stream_name": "system-logs"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

echo "Waiting for EBS volumes to be attached..."
sleep 10

mount_ebs_volume() {
    local device=$1
    local mount_point=$2
    local label=$3
    if [ ! -b "$device" ]; then
        echo "Device $device not found, skipping..."
        return
    fi
    if ! blkid "$device" &>/dev/null; then
        echo "Formatting $device..."
        mkfs -t xfs "$device"
    fi

    mkdir -p "$mount_point"

    local uuid=$(blkid -s UUID -o value "$device")

    if ! grep -q "$uuid" /etc/fstab; then
        echo "UUID=$uuid $mount_point xfs defaults,nofail 0 2" >> /etc/fstab
    fi
    mount -a

    echo "Volume $device mounted at $mount_point"
}

if [ -b /dev/nvme1n1 ]; then
    mount_ebs_volume /dev/nvme1n1 /data1 "data-volume-1"
elif [ -b /dev/sdf ]; then
    mount_ebs_volume /dev/sdf /data1 "data-volume-1"
fi

if [ -b /dev/nvme2n1 ]; then
    mount_ebs_volume /dev/nvme2n1 /data2 "data-volume-2"
elif [ -b /dev/sdg ]; then
    mount_ebs_volume /dev/sdg /data2 "data-volume-2"
fi

chmod 755 /data1 /data2
echo "User data script completed successfully at $(date)" >> /var/log/user-data.log
df -h | grep -E '(/data|Filesystem)' >> /var/log/user-data.log
