import os
import string
import random
import argparse
import requests


def upload_follow(addr, user_0, user_1):
  payload = {'user_name': 'username_' + user_0,
             'followee_name': 'username_' + user_1}
  return requests.post(addr + '/wrk2-api/user/follow', payload)

def upload_register(addr, user):
  payload = {'first_name': 'first_name_' + user, 'last_name': 'last_name_' + user,
             'username': 'username_' + user, 'password': 'password_' + user, 'user_id': user}
  return requests.post(addr + '/wrk2-api/user/register', payload)

def upload_compose(addr, user_id, num_users):
  text = ''.join(random.choices(string.ascii_letters + string.digits, k=256))
  # user mentions
  for _ in range(random.randint(0, 5)):
    text += ' @username_' + str(random.randint(0, num_users))
  # urls
  for _ in range(random.randint(0, 5)):
    text += ' http://' + \
        ''.join(random.choices(string.ascii_lowercase + string.digits, k=64))
  # media
  media_ids = []
  media_types = []
  for _ in range(random.randint(0, 5)):
    media_ids.append('\"' + ''.join(random.choices(string.digits, k=18)) + '\"')
    media_types.append('\"png\"')
  payload = {'username': 'username_' + str(user_id),
             'user_id': str(user_id),
             'text': text,
             'media_ids': '[' + ','.join(media_ids) + ']',
             'media_types': '[' + ','.join(media_types) + ']',
             'post_type': '0'}
  return requests.post(addr + '/wrk2-api/post/compose', payload)


def getNumNodes(file):
  return int(file.readline())


def getEdges(file):
  edges = []
  lines = file.readlines()
  for line in lines:
    edges.append(line.split())
  return edges


def printResults(results):
  for result in results:
    if result.status_code != 200:
      print('Error:', result.status_code, result.text)


def register(addr, nodes):
  results = []
  print('Registering Users...')
  for i in range(nodes):
      results.append(upload_register(addr, str(i)))
  printResults(results)


def follow(addr, edges):
  results = []
  print('Adding follows...')
  for edge in edges:
    results.append(upload_follow(addr, edge[0], edge[1]))
    results.append(upload_follow(addr, edge[1], edge[0]))
  printResults(results)

def compose(addr, nodes):
  results = []
  print('Composing posts...')
  for i in range(nodes):
    for _ in range(random.randint(0, 20)):  # up to 20 posts per user, average 10
      results.append(upload_compose(addr, i+1, nodes))
  printResults(results)


if __name__ == '__main__':

  parser = argparse.ArgumentParser('DeathStarBench social graph initializer.')
  parser.add_argument(
      '--graph', help='Graph name. (`socfb-Reed98`, `ego-twitter`, or `soc-twitter-follows-mun`)', default='socfb-Reed98')
  parser.add_argument(
      '--ip', help='IP address of socialNetwork NGINX web server. ', default='127.0.0.1')
  parser.add_argument(
      '--port', help='IP port of socialNetwork NGINX web server.', default=8080)
  parser.add_argument('--compose', action='store_true',
                      help='intialize with up to 20 posts per user', default=False)
  parser.add_argument('--limit', type=int, help='total number simultaneous connections', default=200)
  args = parser.parse_args()

  with open(os.path.join('datasets/social-graph', args.graph, f'{args.graph}.nodes'), 'r') as f:
    nodes = getNumNodes(f)
  with open(os.path.join('datasets/social-graph', args.graph, f'{args.graph}.edges'), 'r') as f:
    edges = getEdges(f)

  random.seed(1)   # deterministic random numbers

  addr = 'http://{}:{}'.format(args.ip, args.port)
  register(addr, nodes)
  follow(addr, edges)
  if args.compose:
    compose(addr, nodes)