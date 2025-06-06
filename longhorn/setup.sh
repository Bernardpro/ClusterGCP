curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.7.2/scripts/environment_check.sh | bash
sudo apt-get install open-iscsi
sudo modprobe iscsi_tcp
sudo systemctl enable iscsid
sudo systemctl start iscsid
sudo apt-get install nfs-common
sudo systemctl stop multipathd multipathd.socket
sudo systemctl disable multipathd multipathd.socket