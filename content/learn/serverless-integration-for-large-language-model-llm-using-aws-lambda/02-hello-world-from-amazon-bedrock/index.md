---
date: '2025-09-09T23:50:42Z'
draft: false
title: '2 - Hello World from Amazon Bedrock'
description: "Calling Llama 3.2 from AWS Lambda"
summary: "Run Python code in AWS Lambda and send prompt to Llama 3.2 hosted in Amazon Bedrock"
tags: ["AWS Lambda", "Amazon Bedrock", "Serverless"]
---

## Overview

We are going to chat with the Meta Llama 3.2 hosted in Amazon Bedrock by sending a prompt using AWS Lambda.

## Amazon Bedrock

AWS Bedrock is a fully managed Amazon Web Services (AWS) service that provides access to various leading foundational AI models from providers like AI21 Labs, Anthropic, Meta, Mistral AI, Stability AI, and Amazon itself.

The Llama model is accessed through an inference profile. Permission need to be granted to both the model and the inference profile for invoking the model. If the inference profile is cross-region then permission need to be grant to models in each of the regions. The extra layer of this inference profile is mainly used for tracking model usage.

- Log into your AWS managment console, then go to **Bedrock** service.
- From the left-hand side navigation panel open **Model access**.
- Click on the **Modify model access** button.
- Search for `Llama 3.2 1B` in the search box.
- Tick the checkbox to choose this model and then click on the **Next** button.
- On the next page click on the **Submit** button.

Now we have grant access to the Llama 3.2 1B model. More on permission after we create the Lambda.

## AWS Lambda

We are going to create a Python-based Lambda to invoke the Llama 3.2 1B model with the same prompt we used locally.

- Open **Lambda** console.
- Click the **Create function** button. (If this is the first time the button you see could be **Create a function**)
- Use `llm-with-lambda` as the **Function name**.
- Use `Python 3.11` as the **Runtime**.
- Use `arm64` as the **Architecture**.
- Leave everything else in default and click the **Create function** button.

Now remove all the initial Python code provided in the `lambda_function.py` source file in the **Code source**.

Copy the following code into the file, and hit the **Deploy** button on the left-hand side. This deploys the latest code change to the Lambda environment.

```python
import json
import boto3
import os

# Your inference profile ARN from Step 1
INFERENCE_PROFILE_ARN = "Placeholder for inference profile ARN"
DEFAULT_PROMPT = "Give me a fun fact about serverless technology."

# The Bedrock Runtime client to invoke the model
bedrock_runtime = boto3.client(
    service_name='bedrock-runtime',
    region_name=os.environ.get('us-east-1')
)

def lambda_handler(event, context):
    """
    Invokes a Bedrock model using an inference profile 
    and returns the response.
    """
    # Extract the user prompt from the Lambda event payload
    prompt = event.get('prompt', DEFAULT_PROMPT)

    # The message payload for the Converse API
    messages = [
        {
            "role": "user",
            "content": [{"text": prompt}]
        }
    ]

    try:
        response = bedrock_runtime.converse(
            modelId=INFERENCE_PROFILE_ARN,  # Use the profile ARN here
            messages=messages
        )

        # Extract the content from the response
        output_message = response['output']['message']['content'][0]['text']

        return {
            'statusCode': 200,
            'body': json.dumps({'response': output_message})
        }

    except Exception as e:
        print(f"Error invoking Bedrock model: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
```

Next we need to sort out some permissions for this Lambda function so that it can access the Llama 3.2 model hosted in Bedrock.

- Scroll to the top and select the **Configuration** tab among the Code, Test, Monitor etc.
- Select **Permissions** from the left-hand side navigation.
- In the Execution role section the **Role name** filed has a link that starts as `llm-with-lambda-role-...` is the identity this Lambda function uses during execution. Click on the Role name **link**.

We will need to add an inline policy here for this execution role after finishing setting up the permission in Bedrock. So please **keep this tab open**.

## Execution role IAM permission

Open **Bedrock** in a **separate tab**.

- From the left-hand side navigation panel open **Model catalog**.
- Search `Llama 3.2 1B` and open this model.
- Copy the model's **Model ID** value. (e.g. `meta.llama3-2-1b-instruct-v1:0`)
- Prepare the model's ARN by replacing the Model ID placeholder with the actual value. This ARN will be used in the inline permission for the Lambda's execution role.
    ```
    # Model ARN Template
    arn:aws:bedrock:us-east-1::foundation-model/<Model ID>

    # Actual ARN example.
    arn:aws:bedrock:us-east-1::foundation-model/meta.llama3-2-1b-instruct-v1:0
    ```
- From the left-hand side navigation panel open **Cross-region inference**.
- Search `Llama 3.2 1B` in the **Inference profiles** search box. Choose `Model=Llama 3.2 1B Instruct`.
- Copy the inference profile's ARN value from the **Inference profile ARN** column.
    ```
    # Example inference profile ARN. (Note: Account ID is faked.)
    arn:aws:bedrock:us-east-1:123456789012:inference-profile/us.meta.llama3-2-1b-instruct-v1:0
    ```

As a sidenote, from the ARN's tokens we can guess the models are shared across all AWS account in one region while the inference profile is created for each account.

- Go back to the **IAM** console tab that remained open for the Lambda's execution role.
- Click on the **Add permission** dropdown, and choose **Create inline policy**.
- Open the **JSON view** and replace with the following statement. Replace the faked Account ID with yours.
    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "Statement1",
                "Effect": "Allow",
                "Action": [
                    "bedrock:InvokeModel"
                ],
                "Resource": [
                    "arn:aws:bedrock:us-east-1::foundation-model/meta.llama3-2-1b-instruct-v1:0",
                    "arn:aws:bedrock:us-west-2::foundation-model/meta.llama3-2-1b-instruct-v1:0",
                    "arn:aws:bedrock:us-east-1:123456789012:inference-profile/us.meta.llama3-2-1b-instruct-v1:0",
                ]
            }
        ]
    }
    ```

Note that we included the Llama 3.2 1B model from both east and west regions here. This is because the system inference profile we used is cross-region which routes requests to both east and west where resources are more available.

Replace the `"Placeholder for inference profile ARN"` with the actual ARN value in `lambda_function.py` in Lambda.

## Test

The Lambda is ready, and the permission is set so it's time to test.

- Open the `llm-with-lambda` Lambda function from the **management console**.
- Click on the **Test** tab below the Function overview section.
- Replace the **Event JSON** with the following content in the Test event section.

  ```json
  {
    "prompt": "Hello from the devcontainer with Pipenv!"
  }
  ```

- First click on **Save** so that we can reuse this test event later. Next click on the **Test** button.
- It's very possible to run into a `Task timed out` error when running this Lambda for the first time. This is because the default timeout setting for a Lambda function is three seconds (3 sec).

  ```json
  {
    "errorType": "Sandbox.Timedout",
    "errorMessage": "RequestId: 327ec045-e1e7-45f8-8369-c7950e1a5f6f Error: Task timed out after 3.00 seconds"
  }
  ```

- A proper fix is to go to the Configuration tab and update the **Timeout** value to one minute (1 min) in the **General configuration** settings.
- Now we can rerun the test in the **Test** tab. The possible outcome should be similar to the following.

  ```json
  {
    "statusCode": 200,
    "body": "{\"response\": \"Hello from the DevContainer with Pipenv. It's great to see you're using a modern tooling setup. DevContainers and Pipenv are a powerful combination for building and managing your Python applications.\\n\\nWhat's your current project setup? Are you using a specific framework (e.g., Django, Flask) or a library (e.g., requests, pandas)? And what kind of development are you doing (e.g., testing, deployment, CI/CD)?\"}"
  }
  ```

## Congratulations !! :tada:

