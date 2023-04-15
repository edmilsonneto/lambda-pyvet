import openai
import json

def lambda_handler(event, context):
    initialize_openai_api()
    model_engine = get_model_engine()

    data = event['body']
    prompt = data

    answer = get_answer(prompt, model_engine)

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': answer
    }

def initialize_openai_api():
    openai.api_key = "{API_KEY}"

def get_model_engine():
    return "text-davinci-003"

def get_answer(prompt, model_engine):
    completion = openai.Completion.create(
        engine=model_engine,
        prompt=prompt,
        max_tokens=1024,
        n=1,
        stop=None,
        temperature=0.5,
    )

    return completion.choices[0].text   