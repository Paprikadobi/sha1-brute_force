from sha1 import sha1, to_hex, from_hex, brute_force
import string
import argparse

import time

chars = string.ascii_letters + string.digits + '@_!#$%^&*()<>?~:'

def hash_password():
    print('Vložte heslo: ')
    password = input()

    hash = sha1(password.encode())

    print('Zahešované heslo: {}'.format(to_hex(*hash)))

def brute_force_password(args):
    min_length = args['min'] if args['min'] else 1
    max_length = args['max'] if args['max'] else 6
    num_threads = args['threads'] if args['threads'] else 2

    print('Vložte zahešované heslo: ')
    hash = from_hex(input())

    start = time.time()
    
    result = brute_force(chars.encode(), *hash, min_length = min_length, max_length = max_length, num_threads = num_threads, buff_size = len(chars))

    print(time.time() - start)
    if result == -1:
        print('Heslo neprolomeno')
    else:
        print('Heslo prolomeno: {}'.format(result.decode('UTF-8')))

def main(args):
    if args['hash']:
        hash_password()
    else:
        brute_force_password(args)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--hash', required = False, action='store_true', help = 'hashing mode')
    parser.add_argument('--min', required = False, help = 'min length of password to test', type = int)
    parser.add_argument('--max', required = False, help = 'max length of password to test', type = int)
    parser.add_argument('--threads', required = False, help = 'number of threads', type = int)
    args = vars(parser.parse_args())
    main(args)
