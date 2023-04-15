# import jwt

def lambda_handler(event, context):
    # Extrai o token do cabeçalho Authorization
    # authorization_header = event['headers'].get('Authorization', '')
    # token = authorization_header.replace('Bearer ', '')

    # Verifica a validade do token
    # try:
    #     decoded_token = jwt.decode(token, 'OjeWbrAXeVFI_IKeNM3L-TACOP-ByZnyx4307NE1qVc', algorithms=['HS256'])
    # except:
    #     return generate_policy('user', 'Deny', event['methodArn'])

    # Cria a política de autorização com base nas informações do token
    # user_id = decoded_token.get('sub')
    # user_roles = decoded_token.get('roles', [])
    allowed_resources = []
    # if 'admin' in user_roles:
    allowed_resources.append('arn:aws:execute-api:*:*:*/*/*/*')
    # else:
        # allowed_resources.append('arn:aws:execute-api:*:*:*/*/GET/public/*')
    policy = generate_policy(1, 'Allow', allowed_resources)

    return policy

def generate_policy(principal_id, effect, resource):
    policy_document = {
        'Version': '2012-10-17',
        'Statement': {
            'Action': 'execute-api:Invoke',
            'Effect': effect,
            'Resource': resource
        }
    }
    return {
        'principalId': principal_id,
        'policyDocument': policy_document
    }