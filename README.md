# EC2IndexPage
A simple HTML/CSS/JS page that dynamically displays EC2 instance info. 

Example: http://awselb.linuxabuser.com/

## Requirements
### DynamoDB
This page calls a DynamoDB table called `InstanceTable`. It should be set up with 2 keys, like below.

![DynamoDB](https://github.com/tylerapplebaum/EC2IndexPage/blob/master/docs/dynamodb_table.PNG "DynamoDB")

You can create the table programatically, or just use the web interface, since it's so simple.

### Cognito
My process loosely followed [this AWS guide](https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/getting-started-browser.html). Your Cognito identity pool should look something like this when you're done. **Note:** the key is to enable access to unauthenticated identities.

![Cognito](https://github.com/tylerapplebaum/EC2IndexPage/blob/master/docs/cognito.PNG "Cognito")

### IAM
After a successful Cognito identity pool creation, you should see 2 IAM roles, one with *auth* in the name, one with *unauth* in the name. Make sure you're working in the *unauth* role, otherwise you'll see a bunch of 400 requests.

![IAM1](https://github.com/tylerapplebaum/EC2IndexPage/blob/master/docs/iam1.png "IAM1")

The IAM policy needed (shown above as DDB-Anon-Policy) is very simplistic. We're only concerned with the GetItem call on **our specific DynamoDB table**. Replace region and account ID with your own in the policy below. Also, if you chose to name your DynamoDB table something other than InstanceTable, you'll need to change that in the IAM policy and the JavaScript in the index.html file.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "dynamodb:GetItem",
            "Resource": "arn:aws:dynamodb:REGION:ACCOUNTID:table/InstanceTable"
        }
    ]
}
```

In order to have the EC2 instance post its own info to the DynamoDB table, we'll need to create and attach an EC2 role. The IAM policy is as follows:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "dynamodb:PutItem",
            "Resource": "arn:aws:dynamodb:REGION:ACCOUNTID:table/InstanceTable"
        }
    ]
}
```

The policy was attached to an IAM role for EC2, shown below.

![EC2IAM](https://github.com/tylerapplebaum/EC2IndexPage/blob/master/docs/ec2role.png "EC2IAM")

## Operation
If everything goes well, you should see this in the browser:

![Success](https://github.com/tylerapplebaum/EC2IndexPage/blob/master/docs/success.PNG "Success")

Watch the requests roll in across your EC2 instances: `sudo tail -f /var/log/httpd/access_log`

## To-Do
* ~~8/14/19: I haven't yet created a mechanism to automatically post the EC2 instance ID and IPv4 address to the Dynamo table. Maybe a simple AWS CLI function in the bootstrap script. For now, I've manually added them to test with.~~

  * 8/15/19: This has been resolved. AWS CLI invokes a DynamoDB PUT.

* ~~8/14/19: The JavaScript needs to dynamically pull the parameter, likely from a local file containing the instance ID. That file can be created by the same future bootstrap script.~~

  * 8/15/19: This is also resolved. The bootstrap.sh script "dynamically" generates the index.html page on boot, filling in the instance ID.

* 8/15/19: If I choose to clean up the DynamoDB table, I'll probably want an external Lambda function to do that. It could check for currently running instances and delete anything not matching a currently running instance ID.

* 8/15/19: It would be nice to see some other info besides the IP address, like instance type, or something else from the metadata.
