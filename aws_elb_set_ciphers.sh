#!/bin/bash
set -e
aws_bin=$(which aws)
datestamp=$(date '+%s')
ELB_POLICYNAME="PingOneAWS-$datestamp"
ELB_NAME=''
ELB_LISTENPORT=''
ELB_REGION=''
LEGACY_CIPHERS=false
USAGE='usage: ./aws_elb_set_ciphers [OPTIONS]'
NORM=`tput sgr0`
BOLD=`tput bold`
IMPORT_FROM_FILE=false
FILE=''
# prompt [region,lbname,policyname]
function HELP {
  echo -e \\n"Help documentation for aws_elb_set_ciphers"\\n
  echo -e "Basic usage:./aws_elb_set_ciphers.sh [OPTIONS]"\\n
  echo "Command line switches are optional. The following switches are recognized."
  echo "${BOLD}-f${NORM}  Import settings from a comma-separated file."
  echo "Contents MUST be in the order 'AWS Region', 'ELB Name', 'ELB Listen Port'.  See example.csv for guidance"
  echo "${BOLD}-l${NORM}  Sets the ELB Listen Port (e.g. '443' or '8080'). Default is undefined, you will be prompted."
  echo "${BOLD}-n${NORM}  Sets the ELB Name you wish to alter (e.g. 'ort-pingid-bo'). Default is undefined, you will be prompted."
  echo "${BOLD}-p${NORM}  Sets the ELB Policy Name you wish to create (e.g. 'PingOneAWS-20151222'). Default is 'PingOneAWS-<epoch>'."
  echo "${BOLD}-n${NORM}  Sets the AWS Region containing the ELB wish to alter (e.g. 'us-west-2'). Default is undefined, you will be prompted."
  echo -e "${BOLD}-h${NORM}  Displays this help message. No further functions are performed."\\n
  echo -e "Example: ${BOLD} ./aws_elb_set_ciphers -l 443 -n ort-pingid -p PingOneAWS-20151222 -n us-east-1 ${NORM}"\\n
  exit 1
}

function CREATE_LEGACY_CIPHER_POLICY {
  echo "Creating Legacy Cipher List for ELB $ELB_NAME in AWS Region $ELB_REGION..."
  $aws_bin --output text elb create-load-balancer-policy --region=$ELB_REGION --load-balancer-name $ELB_NAME --policy-name $ELB_POLICYNAME --policy-type-name SSLNegotiationPolicyType --policy-attributes AttributeName=Protocol-TLSv1.2,AttributeValue=true AttributeName=Protocol-TLSv1.1,AttributeValue=true AttributeName=Protocol-TLSv1,AttributeValue=true AttributeName=DHE-RSA-AES256-SHA256,AttributeValue=true AttributeName=Server-Defined-Cipher-Order,AttributeValue=true AttributeName=ECDHE-ECDSA-AES128-GCM-SHA256,AttributeValue=true AttributeName=ECDHE-RSA-AES128-GCM-SHA256,AttributeValue=true AttributeName=ECDHE-ECDSA-AES128-SHA256,AttributeValue=true AttributeName=ECDHE-RSA-AES128-SHA256,AttributeValue=true AttributeName=ECDHE-ECDSA-AES128-SHA,AttributeValue=true AttributeName=ECDHE-RSA-AES128-SHA,AttributeValue=true AttributeName=DHE-RSA-AES128-SHA,AttributeValue=true AttributeName=ECDHE-ECDSA-AES256-GCM-SHA384,AttributeValue=true AttributeName=ECDHE-RSA-AES256-GCM-SHA384,AttributeValue=true AttributeName=ECDHE-ECDSA-AES256-SHA384,AttributeValue=true AttributeName=ECDHE-RSA-AES256-SHA384,AttributeValue=true AttributeName=ECDHE-RSA-AES256-SHA,AttributeValue=true AttributeName=ECDHE-ECDSA-AES256-SHA,AttributeValue=true AttributeName=AES128-GCM-SHA256,AttributeValue=true AttributeName=AES128-SHA256,AttributeValue=true AttributeName=AES128-SHA,AttributeValue=true AttributeName=AES256-GCM-SHA384,AttributeValue=true AttributeName=AES256-SHA256,AttributeValue=true AttributeName=AES256-SHA,AttributeValue=true AttributeName=DHE-DSS-AES128-SHA,AttributeValue=true AttributeName=ECDHE-RSA-RC4-SHA,AttributeValue=true AttributeName=RC4-SHA,AttributeValue=true AttributeName=DHE-RSA-AES256-GCM-SHA384,AttributeValue=true AttributeName=DHE-RSA-AES256-SHA256,AttributeValue=true AttributeName=DHE-RSA-AES256-SHA,AttributeValue=true AttributeName=DHE-RSA-AES128-GCM-SHA256,AttributeValue=true AttributeName=DHE-RSA-AES128-SHA256,AttributeValue=true || true
}

function CREATE_MODERN_CIPHER_POLICY {
  echo "Creating Modern Cipher List for ELB $ELB_NAME in AWS Region $ELB_REGION..."
  $aws_bin --output text elb create-load-balancer-policy --region=$ELB_REGION --load-balancer-name $ELB_NAME --policy-name $ELB_POLICYNAME --policy-type-name SSLNegotiationPolicyType --policy-attributes AttributeName=Protocol-TLSv1.2,AttributeValue=true AttributeName=Protocol-TLSv1.1,AttributeValue=true AttributeName=Protocol-TLSv1,AttributeValue=true AttributeName=DHE-RSA-AES256-SHA256,AttributeValue=true AttributeName=Server-Defined-Cipher-Order,AttributeValue=true AttributeName=DHE-RSA-AES256-SHA,AttributeValue=true AttributeName=ECDHE-RSA-AES256-SHA384,AttributeValue=true AttributeName=ECDHE-RSA-AES256-SHA,AttributeValue=true AttributeName=ECDHE-RSA-AES128-GCM-SHA256,AttributeValue=true AttributeName=ECDHE-RSA-AES256-GCM-SHA384,AttributeValue=true AttributeName=DHE-RSA-AES256-GCM-SHA384,AttributeValue=true AttributeName=DHE-RSA-AES128-GCM-SHA256,AttributeValue=true AttributeName=DES-CBC3-SHA,AttributeValue=true || true
}

function CHANGE_ACTIVE_CIPHERS {
  echo "Changing Cipher List on Endpoint $ELB_NAME in AWS Region $ELB_REGION"
  $aws_bin --output text elb set-load-balancer-policies-of-listener  --region=$ELB_REGION --load-balancer-name $ELB_NAME --load-balancer-port $ELB_LISTENPORT --policy-names $ELB_POLICYNAME
  echo "${BOLD}ELB Settings Changed, though your policy may have failed (this isn't necessarily bad; please see output)${NORM}"
  echo "${BOLD}Please check the AWS Console for confirmation${NORM}"
}

function PROMPT_ELB_REGION {
  if [ -z "$ELB_REGION" ]; then
    read -p "aws region:" ELB_REGION
    CHECK_ELB_REGION
  fi
}

function CHECK_ELB_REGION {
  if [ -z "$ELB_REGION" ]; then
    echo -e "\tmissing aws region. Failing run."
    exit 1
  fi
}

function PROMPT_ELB_NAME {
  if [ -z "$ELB_NAME" ]; then
    read -p "elb name:" ELB_NAME
    CHECK_ELB_NAME
  fi
}

function CHECK_ELB_NAME {
  if [ -z "$ELB_NAME" ]; then
    echo -e "\tmissing elb name. Failing run."
    exit 1
  fi
}

function PROMPT_ELB_POLICYNAME {
  if [ -z "$ELB_POLICYNAME" ]; then
    read -p "elb policy name:" ELB_POLICYNAME
    CHECK_ELB_POLICYNAME
  fi
}

function CHECK_ELB_POLICYNAME {
  if [ -z "$ELB_POLICYNAME" ]; then
    echo -e "\tmissing elb policy name. Failing run."
    exit 1
  fi
}

function PROMPT_ELB_LISTENPORT {
  if [ -z "$ELB_LISTENPORT" ]; then
    read -p "elb listen port:" ELB_LISTENPORT
    CHECK_ELB_LISTENPORT
  fi
}

function CHECK_ELB_LISTENPORT {
  if [ -z "$ELB_LISTENPORT" ]; then
    echo -e "\tmissing elb listen port. Failing run."
    exit 1
  fi
}

function MAKE_CIPHER_LIST {
  if [[ $LEGACY_CIPHERS == true ]]; then
    CREATE_LEGACY_CIPHER_POLICY
  else
    CREATE_MODERN_CIPHER_POLICY
  fi
}

while getopts 'f:hl:n:op:r:' flag; do
  case "${flag}" in
    f) echo "Importing options from file $OPTARG..."
    IMPORT_FROM_FILE=true
    FILE=$OPTARG ;;
    h) HELP ;;
    l) echo "ELB Listen Port: $OPTARG"
    ELB_LISTENPORT=$OPTARG ;;
    n) echo "ELB Name: $OPTARG"
    ELB_NAME=$OPTARG ;;
    o) LEGACY_CIPHERS=true ;;
    p) echo "ELB Policy Name to $OPTARG"
    ELB_POLICYNAME="$OPTARG" ;;
    r) echo "ELB Region: $OPTARG"
    ELB_REGION="$OPTARG" ;;
    \?) HELP ;;
  esac
done

if [[ $IMPORT_FROM_FILE == true ]]; then
  [ ! -f $FILE ] && { echo "\tCould not read $FILE, required inputs not found. Exiting."; exit 1;}
  OLDIFS=$IFS
  IFS=,
  while read ELB_REGION ELB_NAME ELB_LISTENPORT
  do
    CHECK_ELB_REGION
    CHECK_ELB_NAME
    CHECK_ELB_LISTENPORT
    MAKE_CIPHER_LIST
    CHANGE_ACTIVE_CIPHERS
  done < $FILE
  IFS=$OLDIFS
else
  PROMPT_ELB_REGION
  PROMPT_ELB_NAME
  PROMPT_ELB_LISTENPORT
  MAKE_CIPHER_LIST
  CHANGE_ACTIVE_CIPHERS
fi
exit $?
