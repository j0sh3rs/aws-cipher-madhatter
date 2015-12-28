# PingOne AWS Cipher Setting Script
This script is intended to be a simple one off for setting up elb ciphers in AWS.
Taken from various bits of documentation, and cloned from the dao migration script for PingOne:

http://docs.aws.amazon.com/cli/latest/reference/elb/create-load-balancer-policy.html
http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/ssl-config-update.html#ssl-config-update-cli

## To Do:
* Upgrade each variable to function as an array, and iterate overitself to cover multiple LB names that share the same policy names/settings/listen port
