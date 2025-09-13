---
date: '2025-09-12T10:58:30Z'
draft: false
title: '3 - Fetch HTML with an URL'

description: "Extract plain text from URLs using BeautifulSoup for reusable web scraping in AI-driven apps."
summary: "This guide explores how to use BeautifulSoup to extract plain text from URLs and build a reusable web scraper for integration into AI-driven applications like AWS Lambda. It includes step-by-step instructions for creating and testing a Python-based scraper with a modular class design."

tags: ["web-scraping", "beautifulsoup", "python-development", "ai-integration", "url-extraction"]
---

## Overview

Learn to extract plain text from URLs using BeautifulSoup and create a reusable web scraper for seamless integration into AI-driven applications like AWS Lambda.

## Get plain text from an URL

First add the `beautifulsoup4` package to the project.

```bash
pipenv install beautifulsoup4
```

Then create a new file `web_scraper.py`, and add following code to it.

```python
import requests
from bs4 import BeautifulSoup

def get_text_from_url(url: str) -> str:
    """
    Fetches the HTML from a URL and returns the plain text content.
    
    Args:
        url: The URL to fetch.
    
    Returns:
        The plain text content of the webpage.
    
    Raises:
        requests.exceptions.RequestException: If an HTTP request error occurs.
    """
    try:
        # Fetch the HTML content
        response = requests.get(url)
        response.raise_for_status()  # Raise an exception for bad status codes
        
        # Parse the HTML and extract text
        soup = BeautifulSoup(response.text, 'html.parser')
        return soup.get_text(separator='\n', strip=True)
    except requests.exceptions.RequestException as e:
        print(f"Error fetching URL {url}: {e}")
        return ""

# Example of how to use the reusable function
if __name__ == '__main__':
    url_to_scrape = 'https://www.udemy.com/course/llm-engineering-master-ai-and-large-language-models'
    text_content = get_text_from_url(url_to_scrape)
    if text_content:
        print(text_content)
```

Run following command in terminal to test.

```
pipenv run python src/web_scraper.py
```

The output should be something like the following.

{{< details summary="Click to expand/collapse - Sample output">}}
```
LLM Engineering: Master AI, Large Language Models & Agents | Udemy
Search bar
Search for anything
Site navigation
Most popular
More from Udemy
Udemy Business
Get the app
Invite friends
Help and Support
English
Development
Web Development
Data Science
Mobile Development
Programming Languages
Game Development
Database Design & Development
Software Testing
Software Engineering
Software Development Tools
No-Code Development
Business
Entrepreneurship
Communication
Management
Sales
Business Strategy
Operations
Project Management
Business Law
Business Analytics & Intelligence
Human Resources
Industry
E-Commerce
Media
Real Estate
Other Business
Finance & Accounting
Accounting & Bookkeeping
Compliance
Cryptocurrency & Blockchain
Economics
Finance
Finance Cert & Exam Prep
Financial Modeling & Analysis
Investing & Trading
Money Management Tools
Taxes
Other Finance & Accounting
IT & Software
IT Certifications
Network & Security
Hardware
Operating Systems & Servers
Other IT & Software
Office Productivity
Microsoft
Apple
Google
SAP
Oracle
Other Office Productivity
Personal Development
Personal Transformation
Personal Productivity
Leadership
Career Development
Parenting & Relationships
Happiness
Esoteric Practices
Religion & Spirituality
Personal Brand Building
Creativity
Influence
Self Esteem & Confidence
Stress Management
Memory & Study Skills
Motivation
Other Personal Development
Design
Web Design
Graphic Design & Illustration
Design Tools
User Experience Design
Game Design
3D & Animation
Fashion Design
Architectural Design
Interior Design
Other Design
Marketing
Digital Marketing
Search Engine Optimization
Social Media Marketing
Branding
Marketing Fundamentals
Marketing Analytics & Automation
Public Relations
Paid Advertising
Video & Mobile Marketing
Content Marketing
Growth Hacking
Affiliate Marketing
Product Marketing
Other Marketing
Lifestyle
Arts & Crafts
Beauty & Makeup
Esoteric Practices
Food & Beverage
Gaming
Home Improvement & Gardening
Pet Care & Training
Travel
Other Lifestyle
Photography & Video
Digital Photography
Photography
Portrait Photography
Photography Tools
Commercial Photography
Video Design
Other Photography & Video
Health & Fitness
Fitness
General Health
Sports
Nutrition & Diet
Yoga
Mental Health
Martial Arts & Self Defense
Safety & First Aid
Dance
Meditation
Other Health & Fitness
Music
Instruments
Music Production
Music Fundamentals
Vocal
Music Techniques
Music Software
Other Music
Teaching & Academics
Engineering
Humanities
Math
Science
Online Education
Social Science
Language Learning
Teacher Training
Test Prep
Other Teaching & Academics
Web Development
JavaScript
React JS
Angular
Next.js
Node.Js
ASP.NET Core
CSS
Typescript
AWS Certified Cloud Practitioner
AWS Certified Solutions Architect - Associate
CompTIA Security+
CompTIA A+
Amazon AWS
Cisco Certified Network Associate (CCNA)
CompTIA Network+
Information Security
AWS Certified AI Practitioner
Microsoft Power BI
SQL
Data Modeling
Data Analysis
Business Analysis
Tableau
Business Intelligence (BI)
Generative AI (GenAI)
Data Analysis Expressions (DAX)
Unreal Engine
Unity
Game Development Fundamentals
3D Game Development
C# (programming language)
Godot
2D Game Development
ROBLOX Game Development
C++ (programming language)
Google Flutter
React Native
Dart (programming language)
Android Development
iOS Development
Swift
SwiftUI
Kotlin
Mobile App Development
Stock Options
Financial Accounting
Accounting
Financial Modeling
Fintech
Finance Fundamentals
Forex Trading
Graphic Design
Drawing
Adobe Photoshop
Adobe Illustrator
Canva
Procreate Digital Illustration App
Adobe InDesign
Digital Painting
Design Theory
Life Coach Training
Personal Development
Neuro-Linguistic Programming (NLP)
Personal Transformation
Sound Therapy
Coaching
Mindfulness
Manifestation and Law of Attraction
Energy Healing
Business Fundamentals
Entrepreneurship Fundamentals
Truck Dispatching
Freelancing
Business Strategy
Online Business
ChatGPT
Large Language Models (LLM)
Business Plan
Digital Marketing
Social Media Marketing
Marketing Strategy
Internet Marketing
ChatGPT
Google Analytics
Sales Funnel
Copywriting
Facebook Ads
Development
Data Science
Large Language Models (LLM)
Preview this course
LLM Engineering: Master AI, Large Language Models & Agents
Become an LLM Engineer in 8 weeks: Build and deploy 8 LLM apps, mastering Generative AI, RAG, LoRA and AI Agents.
Bestseller
Created by
Ligency Team
,
Ed Donner
Last updated 12/2024
English
English [Auto], Arabic [Auto]
,
18 more
Premium
4.7
Rating: 4.7 out of 5
17,425 ratings
136,424
learners
Preview this course
What you'll learn
Project 1: Make AI-powered brochure generator that scrapes and navigates company websites intelligently.
Project 2: Build Multi-modal customer support agent for an airline with UI and function-calling.
Project 3: Develop Tool that creates meeting minutes and action items from audio using both open- and closed-source models.
Project 4: Make AI that converts Python code to optimized C++, boosting performance by 60,000x!
Project 5: Build AI knowledge-worker using RAG to become an expert on all company-related matters.
Project 6: Capstone Part A – Predict product prices from short descriptions using Frontier models.
Project 7: Capstone Part B – Execute Fine-tuned open-source model to compete with Frontier in price prediction.
Project 8: Capstone Part C – Build Autonomous multi agent system collaborating with models to spot deals and notify you of special bargains.
Compare and contrast the latest techniques for improving the performance of your LLM solution, such as RAG, fine-tuning and agentic workflows
Weigh up the leading 10 frontier and 10 open-source LLMs, and be able to select the best choice for a given task
Requirements
Familiarity with Python. This course will not cover Python basics and is completed in Python.
A PC with an internet connection is required. Either Mac (Linux) or Windows.
We recommend that you allocate around $5 for API costs to work with frontier models. However, you can complete the course using open-source models if you prefer.
Description
Mastering Generative AI and LLMs: An 8-Week Hands-On Journey
Accelerate your career in AI with practical, real-world projects led by industry veteran Ed Donner. Build advanced Generative AI products, experiment with over 20 groundbreaking models, and master state-of-the-art techniques like RAG, QLoRA, and Agents.
What you’ll learn
•
Build advanced Generative AI products
using cutting-edge models and frameworks.
•
Experiment with over 20 groundbreaking AI models
, including Frontier and Open-Source models.
•
Develop proficiency with platforms
like HuggingFace, LangChain, and Gradio.
•
Implement state-of-the-art techniques
such as RAG (Retrieval-Augmented Generation), QLoRA fine-tuning, and Agents.
•
Create real-world AI applications
, including:
• A multi-modal customer support assistant that interacts with text, sound, and images.
• An AI knowledge worker that can answer any question about a company based on its shared drive.
• An AI programmer that optimizes software, achieving performance improvements of over 60,000 times.
• An ecommerce application that accurately predicts prices of unseen products.
•
Transition from inference to training
, fine-tuning both Frontier and Open-Source models.
•
Deploy AI products to production
with polished user interfaces and advanced capabilities.
•
Level up your AI and LLM engineering skills
to be at the forefront of the industry.
About the Instructor
I’m
Ed Donner
, an entrepreneur and leader in AI and technology with over 20 years of experience. I’ve co-founded and sold my own AI startup, started a second one, and led teams in top-tier financial institutions and startups around the world. I’m passionate about bringing others into this exciting field and helping them become experts at the forefront of the industry.
Projects:
Project 1
: AI-powered brochure generator that scrapes and navigates company websites intelligently.
Project 2
: Multi-modal customer support agent for an airline with UI and function-calling.
Project 3
: Tool that creates meeting minutes and action items from audio using both open- and closed-source models.
Project 4
: AI that converts Python code to optimized C++, boosting performance by 60,000x!
Project 5
: AI knowledge-worker using RAG to become an expert on all company-related matters.
Project 6
: Capstone Part A – Predict product prices from short descriptions using Frontier models.
Project 7
: Capstone Part B – Fine-tuned open-source model to compete with Frontier in price prediction.
Project 8
: Capstone Part C – Autonomous agent system collaborating with models to spot deals and notify you of special bargains.
Why This Course?
•
Hands-On Learning:
The best way to learn is by doing. You’ll engage in practical exercises, building real-world AI applications that deliver stunning results.
•
Cutting-Edge Techniques:
Stay ahead of the curve by learning the latest frameworks and techniques, including RAG, QLoRA, and Agents.
•
Accessible Content:
Designed for learners at all levels. Step-by-step instructions, practical exercises, cheat sheets, and plenty of resources are provided.
•
No Advanced Math Required:
The course focuses on practical application. No calculus or linear algebra is needed to master LLM engineering.
Course Structure
Week 1: Foundations and First Projects
• Dive into the
fundamentals of Transformers
.
• Experiment with
six leading Frontier Models
.
• Build your first business Gen AI product that scrapes the web, makes decisions, and creates formatted sales brochures.
Week 2: Frontier APIs and Customer Service Chatbots
• Explore
Frontier APIs
and interact with three leading models.
• Develop a customer service chatbot with a sharp UI that can interact with
text, images, audio
, and utilize
tools or agents
.
Week 3: Embracing Open-Source Models
• Discover the world of
Open-Source models
using HuggingFace.
• Tackle
10 common Gen AI use cases
, from translation to image generation.
• Build a product to generate
meeting minutes and action items
from recordings.
Week 4: LLM Selection and Code Generation
• Understand the
differences between LLMs
and how to select the best one for your business tasks.
• Use LLMs to
generate code
and build a product that translates code from Python to C++, achieving performance improvements of over
60,000 times
.
Week 5: Retrieval-Augmented Generation (RAG)
• Master
RAG
to improve the accuracy of your solutions.
• Become proficient with
vector embeddings
and explore vectors in popular open-source vector datastores.
• Build a full business solution similar to real products on the market today.
Week 6: Transitioning to Training
• Move from
inference to training
.
• Fine-tune a
Frontier model
to solve a real business problem.
• Build your own
specialized model
, marking a significant milestone in your AI journey.
Week 7: Advanced Training Techniques
• Dive into advanced training techniques like
QLoRA fine-tuning
.
• Train an
open-source model
to outperform Frontier models for specific tasks.
• Tackle challenging projects that push your skills to the next level.
Week 8: Deployment and Finalization
• Deploy your commercial product to production with a polished
UI
.
• Enhance capabilities using
Agents
.
• Deliver your first
productionized, agentized, fine-tuned LLM model
.
• Celebrate your mastery of AI and LLM engineering, ready for a new phase in your career.
Who this course is for:
Aspiring AI engineers and data scientists eager to break into the field of Generative AI and LLMs.
Professionals looking to upskill and stay competitive in the rapidly evolving AI landscape.
Developers interested in building advanced AI applications with practical, hands-on experience.
Individuals seeking a career transition or aiming to enhance productivity through LLM-built frameworks.
Show more
Show less
Instructors
Ligency Team
Helping Data Scientists Succeed
4.6 Instructor Rating
986,252 Reviews
3,443,073 Students
120 Courses
Hi there,
We are the Ligency PR and Marketing team. You will be hearing from us when new courses are released, when we publish new podcasts, blogs, share cheatsheets and more!
We are here to help you stay on the cutting edge of Data Science and Technology.
See you in class,
Sincerely,
The Real People at Ligency
Show more
Show less
Ed Donner
AI startup co-founder and leader; Gen AI and LLM instructor
4.7 Instructor Rating
32,293 Reviews
218,281 Students
8 Courses
Ed Donner is a technology leader and repeat founder of AI startups. He’s the co-founder and CTO of Nebula, the platform to source, understand, engage and manage talent, using Generative AI and other forms of machine learning. Nebula’s long-term goal is to help people discover their potential and pursue their reason for being.
Previously, Ed was the founder and CEO of AI startup untapt, an Accenture Fintech Innovation Lab company, acquired in 2021. Before that, Ed was a Managing Director at JPMorgan Chase, leading a team of 300 software engineers in Risk Technology across 3 continents, after a 15-year technology career on Wall Street. Ed holds a patent for a Deep Learning matching engine issued in 2023, and an MA in Physics from Oxford.
Show more
Show less
Top companies choose
Udemy Business
to build in-demand career skills.
English
About us
Contact us
Careers
Investors
Terms
Privacy policy
Blog
Sitemap
Get the app
Accessibility statement
© 2025 Udemy, Inc.
```
{{< /details >}}

## Make it reusable

We need this function in the Lambda handler too.

```python
import requests
from bs4 import BeautifulSoup

class WebScraper:
    """
    A reusable class for fetching and parsing web content.
    """
    def __init__(self, parser='html.parser'):
        """Initializes the scraper with a specific HTML parser."""
        self.parser = parser
        self.session = requests.Session()

    def get_html(self, url: str) -> str:
        """Fetches the raw HTML content from a URL."""
        try:
            response = self.session.get(url)
            response.raise_for_status()
            return response.text
        except requests.exceptions.RequestException as e:
            print(f"Error fetching URL {url}: {e}")
            return ""

    def parse_text(self, html_content: str) -> str:
        """Parses HTML content and extracts the plain text."""
        if not html_content:
            return ""
        soup = BeautifulSoup(html_content, self.parser)
        return soup.get_text(separator='\n', strip=True)

    def scrape_plain_text(self, url: str) -> str:
        """Fetches a URL and returns the plain text content."""
        html_content = self.get_html(url)
        return self.parse_text(html_content)
```

We need some code to test and verify this class works. Please add the following code to the end of the `web_scraper.py`.

```python
# The following code runs only if you execute web_scraper.py directly
# So that this file can be imported into other Python files without
# triggering the execution of this block of code.
if __name__ == '__main__':
    scraper = WebScraper()
    url_to_scrape = 'https://www.udemy.com/course/llm-engineering-master-ai-and-large-language-models'
    
    # Use the combined method
    text_content = scraper.scrape_plain_text(url_to_scrape)
    if text_content:
        print("--- Plain text content ---")
        print(text_content)
```

Run following command in terminal to test. (Same as above)

```
pipenv run python src/web_scraper.py
```

You should see the same result as previously.

## Congratulations !! :tada: