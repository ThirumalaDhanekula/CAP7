#!/bin/bash
registered_inst=""
curr_alb_inst=""
modified_list=""
recipents=""
from=""
subject=""

ALB_Name=$1
git_file_name="demo.txt"
   	
get_inst_details_from_git() {
    if [ ! -f "$git_file_name" ]; then
       echo " Reference file does not exist"	   
       exit
    else    
       while IFS= read -r line; do
           echo "Instance ID in Git: $line"
           if [ "$registered_inst" != "" ];then
              registered_inst="${registered_inst} $line"
           else
              registered_inst="$line"
           fi
       done < "$git_file_name"
    fi    
}

get_alb_instid() {
    echo "ALB_Name: $ALB_Name"

    ALB_ARN=$(aws elbv2 describe-load-balancers --names $ALB_Name --query 'LoadBalancers[0].LoadBalancerArn' --output text)

    TG_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN --query 'TargetGroups[0].TargetGroupArn' --output text)

    inst_list=`aws elbv2 describe-target-health --target-group-arn $TG_ARN --query 'TargetHealthDescriptions[*].Target.Id' --output text | tr -s ' ' `
    curr_alb_inst=$inst_list
    for inst in ${inst_list};
       do
       echo "InstID: ${inst}"
    done
 }

find_modified_inst() {
   for reg_inst in ${registered_inst};do
      found=0
      tmp_list=${curr_alb_inst}
      for tmp_inst in ${tmp_list};do
         if [ "${tmp_inst}" == "${reg_inst}" ];then
            found=1
            break
         fi
      done
      if [ $found -eq 0 ];then
         if [ "${modified_list}" == "" ];then
            #modified_list="${reg_inst}"
            modified_list="${tmp_inst}"
         else
            modified_list="$modified_list ${reg_inst}"
	 fi
      fi
   done
}

send_mail_notification() {

   sendmail "$recipents" <<EOF
subject:$subject
from:$from
$modified_list
EOF
   res=$?
      if [ $res -eq 0 ];then
         echo "Email notification Successful"
      else
         echo "Email notification failed with error $res"
      fi
}
get_inst_details_from_git
get_alb_instid
find_modified_inst

if [ "${modified_list}" != "" ];then
   echo "Send Email with notification for : ${modified_list}"
   #send_mail_notification
else
   echo "No changes found"
fi
