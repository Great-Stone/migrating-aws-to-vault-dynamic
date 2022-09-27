import boto3, json

iam_client = boto3.client('iam')
iam_resource = boto3.resource('iam')

result = {}

groups = iam_client.list_groups()['Groups']
users = iam_client.list_users(MaxItems = 1000)['Users']

for user in users:
  name = user['UserName']
  policy_info = {}
  attated_policies = []
  groups = []
  user_policies = {}

  user_info = iam_resource.User(name)
  for policy in user_info.attached_policies.all():
    attated_policies.append(policy.arn)
  for group in user_info.groups.all():
    groups.append(group.group_name)
  for policy in user_info.policies.all():
    if not bool(user_policies):
      user_policies = policy.policy_document
    else:
      user_policies['Statement'].extend(policy.policy_document['Statement'])

  policy_info['attated_policies'] = attated_policies
  policy_info['groups'] = groups
  policy_info['user_policies'] = user_policies

  result[name] = policy_info

print(result)

with open("./policies_data.json", 'w') as outfile:
    json.dump(result, outfile)
