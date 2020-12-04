import json, requests

def handler(event, context):
    response = {}
    wrapper={}
    r = requests.get('http://127.0.0.1:8000')
    response['event']="Response via Lambda: "+r.text
    wrapper['isBase64Encoded']='false'
    wrapper['statusCode']='200'
    wrapper['headers']={}
    wrapper['body']=json.dumps(response)
    print(response)
    return wrapper


