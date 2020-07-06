#!/bin/bash -e
#
# Run ansible to generate a Packer template from
# config/config_env_packer.yml to define the shared variables
#
set +x

echo "************************"
echo "**   App AMI Bakery "
echo "************************"

# Check if app config file is provided and exists
echo " "
printf "Checking provided config file... "
if [[ ! -f $1 ]]
then
	echo " "
    echo "usage: $0 /fullpath/config_file.yml"
	echo " "
	echo "Error: provided config_file is missing or doesn't exist"
	echo "Aborting "
	echo " "
	exit 1
fi
printf "Ok!\n"

# Pre Req Check
# Check if required commands are installed
echo " "
printf "Checking pre-requisite... "
for item in ansible-playbook \
			packer \
			aws
    do
        command -v "$item" > /dev/null || \
            { echo "requires {$item} but it's not installed. Aborting."; exit 1; }
    done
printf "Ok!\n"


# check we are connected to AWS
# If the command fail, the script will stop
echo " "
echo "Checking AWS CLI connection"
aws_arn=$(aws sts get-caller-identity --output text --query Arn)
echo "connected as $aws_arn"
echo " "

ANSIBLE="ansible-playbook -i 'localhost,'"
PACKER="packer"
AUTO_ROOT=$(pwd)
TMPDIR=$(mktemp -d -t packer.XXXXXX)

set -x

# run ansible
${ANSIBLE} ${AUTO_ROOT}/config/create-image.yml \
	-e app_configfile="${AUTO_ROOT}/${1}" \
	-e ansible_dir="${AUTO_ROOT}/config" \
	-e tmpdir="${TMPDIR}"

set +x

# show the generated templates and its path
cat ${TMPDIR}/genimage.json
echo " "
echo "Path of the generated tempate: "
echo ${TMPDIR}/genimage.json
echo " "


${PACKER} version
${PACKER} inspect ${TMPDIR}/genimage.json

echo "************************"
echo "**   Packer  "
echo "************************"

set -x
AWS_MAX_ATTEMPTS=150 AWS_POLL_DELAY_SECONDS=60 ${PACKER} build -color=false  ${TMPDIR}/genimage.json
set +x

# Cleaning if all went well and script was not interupted by an error
echo " "
printf "\n\n Cleaning temporary files..."
rm -rf ${TMPDIR}
printf " Done!\n"
echo " "
