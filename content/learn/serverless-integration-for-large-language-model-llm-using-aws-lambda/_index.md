---
title: "Serverless Integration for Large Language Model (LLM) using AWS Lambda"
date: 2025-09-10T01:58:47Z
draft: false
description: "Serverless LLM engineering"
summary: "An example of using serverless tech stack to do LLM engineering"
tags: ["Amazon Bedrock", "AWS Lambda", "Serverless"]

showDate : false
showDateUpdated : false
showHeadingAnchors : false
showPagination : false
showReadingTime : false
showTableOfContents : true
showTaxonomies : false 
showWordCount : false
showSummary : false
sharingLinks : false
---

## About

We are going to use an LLM model to summarize a web page and store the outcome into a DynamoDB table. The page is provided through an URL which is also the key used for storing the summarization outcome in the DynamoDB table.

[{{< icon "github" >}}](https://github.com/amoschen-ygtq/llm-with-lambda) **[source code](https://github.com/amoschen-ygtq/llm-with-lambda)**

## Prerequisite

1. A computer. If using Windows please check it's Windows 11 and recent versions of Windows 10 (version 1903 or higher, with build 18362 or higher).
1. An AWS account. You can [create a free account](https://aws.amazon.com/free) if don't have one yet.
1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) by clicking the **Download Docker Desktop**.
1. Install [Visual Studio Code](https://code.visualstudio.com/download), and [DevContainer extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
1. Install [Git](https://git-scm.com/downloads).
1. Clone [this repo]() and open it in Visual Studio Code.
    (Choose "Reopen in container" when being asked)
1. Install AWS CLI and CDK by running the `./script/install_tools.sh` in Visual Studio Code's Integrated Terminal.

## Architecture

![Architecture](/images/course_1_llm_with_lambda/architecture.png)

## References

- Udemy - [LLM Engineering: Master AI, Large Language Models & Agents](https://www.udemy.com/course/llm-engineering-master-ai-and-large-language-models) Created by **Ligency Team**, **Ed Donner**
- GitHub - [llm_engineering](https://github.com/ed-donner/llm_engineering) by **Ed Donner**
- AWS - [Track, allocate, and manage your generative AI cost and usage with Amazon Bedrock](https://aws.amazon.com/blogs/machine-learning/track-allocate-and-manage-your-generative-ai-cost-and-usage-with-amazon-bedrock/) by **Kyle Blocksom** and **Dhawalkumar Patel** on 01 NOV 2024
