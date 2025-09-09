+++
date = '2025-09-02T23:48:42Z'
draft = false
title = 'LLM with Lambda'
+++

# About

We are going to use an LLM model to summarize a web page and store the outcome into a DynamoDB table. The page is provided through an URL which is also the key used for storing the summarization outcome in the DynamodDB table.

**[source code](https://github.com/amoschen-ygtq/llm-with-lambda)**

# Pprerequisite

1. A computer. If using Windows please check it's Windows 11 and recent versions of Windows 10 (version 1903 or higher, with build 18362 or higher).
1. An AWS account. You can [create a free account](https://aws.amazon.com/free) if don't have one yet.
1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) by clicking the **Download Docker Desktop**.
1. Install [Visual Studio Code](https://code.visualstudio.com/download), and [DevContainer extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
1. Install [Git](https://git-scm.com/downloads).
1. Clone [this repo]() and open it in Visual Studio Code.
    (Choose "Reopen in container" when being asked)
1. Install AWS CLI and CDK by running the `./script/install_tools.sh` in Visual Studio Code's Integrated Terminal.

# Architecture

![Architecture](/images/course_1_llm_with_lambda/architecture.png)

# Hello from DevContainer

## Ollama

[Ollama](https://ollama.com/) is a simple, open-source tool that allows you to download, run, and manage large language models (LLMs) on your own computer, making it easier to use powerful AI locally and privately without relying on cloud services.

Open the Ollama website and click on the **[Download](https://ollama.com/download)** link. Install the version that is compatible with your operating system.

Run following command to start using Llama 3.2 in your terminal.

```bash
ollama run llama3.2
```

## Windows users

Click <a href="#skip-wsl-install">here</a> to skip to the next section if you are not using Windows.

Most of our instructions will be based on a Linux-like terminal and Shell environment. To align Windows with Mac and Linux we are going to use the Windows Subsystem for Linux Version 2 (WSL 2) for Windows users.

We need WSL 2 to run our DevContainer environment. For Windows 11 and Windows 10 with version 1903 or higher, with build 18362 or higher WSL will autometically install version 2. Otherwise you have to stop here unfortunately.

Open PowerShell as an administrator and run the command `wsl --install`. This will install WSL and the default Ubuntu distribution. After the installation, you'll need to restart your computer. Once restarted, a setup process will begin in a new window, prompting you to create a Unix username and password for your Linux distribution.

It's always better to verify that a distribution is running on WSL 2. Run command `wsl -l -v` and you should see an output similar to the following.

```
PS C:\Users\user> wsl -l -v
  NAME      STATE     VERSION
* Ubuntu    Running   2
```

Docker will detect WSL and ask for enabling integration. Choose **Enable WSL integration**.

![Enable WSL integration](/images/course_1_llm_with_lambda/1-docker-desktop-wsl-integration.png)

The WSL 2 file system provides a [better performance](https://www.docker.com/blog/docker-desktop-wsl-2-best-practices/) for the Docker engine. This is a [recommended practice](https://code.visualstudio.com/blogs/2020/07/01/containers-wsl) from Microsoft. We will find out more after we set up the DevContainer environment.

<span id="skip-wsl-install"></span>

## DevContainer setup

DevContainers enables the use of a Docker container as a complete development environment within Visual Studio Code. This allows developers to standardize and isolate their development environments, ensuring consistency across teams and projects.

Start with a project folder `llm_with_lambda` and create a sub-folder called `.devcontainer`. Then create a JSON file with name `devcontainer.json` in the sub-folder.

The folder structure looks as the following

```
llm_with_lambda
`-- .devcontainer
    `-- devcontainer.json  # New file
```

Copy and paste the following content into the `devcontainer.json` file.

```json
{
  "name": "Python Dev Container with Pipenv and Ollama Access",
  "image": "mcr.microsoft.com/vscode/devcontainers/python:3.11",
  "runArgs": [
    "--network=host",
    "--add-host=host.docker.internal:host-gateway"
  ],
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance"
      ]
    }
  },
  // No need to run pipenv install after pipenv install --dev. The --dev flag installs both default and development dependencies.
  "postCreateCommand": "pip install --user pipenv && pipenv install --dev",
}
```

Then create a text file with name `Pipfile` in the project root. The folder structure should look like the following.

```
llm_with_lambda
|-- .devcontainer
|   `-- devcontainer.json
`-- Pipfile  # New file
```

Copy the following content to the `Pipfile`.

```
[[source]]
url = "https://pypi.org/simple"
verify_ssl = true
name = "pypi"

[packages]
ollama = "*"
requests = "*"

[dev-packages]

[requires]
python_version = "3.11"
```

By now you have created a bare minimum Python project environment for Visual Studio Code. Next we will verify this setup.

## Verify DevContainer setup

If you don't have Docker running or installed it's time to do this first.

Open Visual Studio Code and then use its **Open Folder...** function under the File menu to open the folder `llm_with_lambda` folder we created previously.

The DevContainer extension will recogonize the `.devcontainer` folder and the settings specified in the JSON file. It will pull the Docker image specified in the JSON from Microsoft and run in your local Docker engine.

Visual Studio Code will then use this Docker container as the development environment.

### Windows users

Click <a href="#skip-open-in-wsl">here</a> to skip to the next section if you are not using Windows.

Let Visual Studio Code open the project folder through WSL is important. This will run the dev container in Linux context with a better file system performance compare to Windows' NTFS file system.

Open the WSL terminal and navigate to the project root folder. Run command `code .` will open Visual Studio Code. The `.` tells Visual Studio Code that the current path is the folder to be opened.

Visual Studio Code will detect it's a WSL context and recommend to install WSL extension. Choose **Install**.

![WSL extension](/images/course_1_llm_with_lambda/3-wsl-extension-recommended.png)

<span id="skip-open-in-wsl"></span>

### Prepare to call Ollama

Next we are going to make a REST API call to the Ollama running on the host.

Create a `src` folder in the project root and add a Python file named as `main.py`. The folder structure should look like the following now.

```
llm_with_lambda
|-- .devcontainer
|   `-- devcontainer.json
|-- src
|   `-- main.py  # New file
|-- Pipfile
`-- Pipfile.lock  # Auto generated by Pipenv
```

A new file (Pipfile.lock) is generated by the `pipenv install --dev` command which is specified in the DevContainer settings in the `postCreateCommand` setting.

```python
from ollama import Client

# Specify the host URL for Ollama's REST API
client = Client(host='http://host.docker.internal:11434')

# Connect to Ollama on the host (localhost works due to --network=host)
response = client.chat(
    model='llama3.2',
    messages=[{'role': 'user', 'content': 'Hello from the devcontainer with Pipenv!'}]
)
print(response['message']['content'])
```

The host `host.docker.internal` is specified in the `runArgs` setting in the DevContainer settings. These arguments are used for starting the dev container running in the Docker engine.

#### `--network`
This flag determines which network stack the container will use, isolating its network from the host or other containers based on the chosen driver.

**`host` network**: This mode removes network isolation, and the container shares the host machine's networking stack directly. The container's application can be accessed via the host's IP address and port without any port mapping. This is useful for performance-intensive applications or network monitoring.

#### `--add-host`
This flag adds a static hostname-to-IP mapping to the container's /etc/hosts file. It is used for manually overriding DNS or providing a custom name for a specific IP address. 

`--add-host=database:192.168.1.5`, for example, adds an entry in the `/etc/hosts` file in the dev container so that we can use `database` as the DNS name instead of the IP address `192.168.1.5` inside the dev container.

**`host-gateway`**, on the other hand, is a special, dynamic string that instructs Docker to automatically resolve to the IP address of the Docker host machine's network gateway. This is used to allow a container to access services running on the host machine itself.

## Calling Ollama

Run following command in Visual Studio Code's terminal to execute the Python code saved in `main.py`.

```bash
pipenv run python src/main.py
```

The output in the Terminal should be similar to the following.

```
You're using a dev container with Pipenv!

The "Hello, world!" greeting is a traditional way to test if someone's code is running correctly. In this case, it seems like your dev container is up and running.

To confirm, I'd be happy to chat with you about your dev container setup or help you troubleshoot any issues you might be facing. What would you like to know or discuss?
```

## Achievment

So far we have created a development environment with an LLM running locally that we can use through our Python code without introducing any cost. When our prompt(s) becomes ready we can switch to the frontier model such as GPT5, Grok4, and Claude Opus.

![Development environment (Mac/Linux)](/images/course_1_llm_with_lambda/dev-environment.png)

### Windows users

The setup in Windows is slightly more involved with an extra layer of Windows Subsystem for Linux.

![Development environment (Windows)](/images/course_1_llm_with_lambda/dev-environment-windows.png)

# Hello from Lambda

Let's replicate what has been done locally into the Cloud. We will use the same Llama 3.2 model and start with 1 billion parameters first to keep the cost low.

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

## Lambda

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

### Execution role IAM permission

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

# References

- Udemy - [LLM Engineering: Master AI, Large Language Models & Agents](https://www.udemy.com/course/llm-engineering-master-ai-and-large-language-models) Created by **Ligency Team**, **Ed Donner**. Last updated 12/2024
- AWS - [Track, allocate, and manage your generative AI cost and usage with Amazon Bedrock](https://aws.amazon.com/blogs/machine-learning/track-allocate-and-manage-your-generative-ai-cost-and-usage-with-amazon-bedrock/) by **Kyle Blocksom** and **Dhawalkumar Patel** on 01 NOV 2024
