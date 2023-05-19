import json
import boto3
import os

def lambda_handler(event, context):
    # TODO implement
    visitor_count=0
    visit:str="Visitor count"
    #define Dynomdb resource
    table_name= os.environ["TABLE_NAME"]
    dynamo = boto3.resource('dynamodb').Table(table_name)

    #Get value

    response=dynamo.get_item(Key={"user":visit})
    if "Item" in response:
        visitor_count = int(response["Item"]["visitor_count"])

    visitor_count+=1
    dynamo.put_item(Item={"user":visit,"visitor_count":visitor_count})
    return {
        'statusCode': 200,
        'body': json.dumps({"count":visitor_count})
    }
