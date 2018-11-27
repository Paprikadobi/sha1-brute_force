from sha1 import sha1, to_hex, brute_force
import string
import time

# from Hack import Hack

chars = string.ascii_letters + string.digits + "@_!#$%^&*()<>?~:"

def main():
    print("Insert password: ")
    password = input()

    hash = sha1(password.encode())

    # print("Hashed password: {}".format(to_hex(*hash)))

    # obj = Hack(chars)

    start = time.time()
    
    result = brute_force(chars.encode(), *hash)
    # result = obj.find_pass(hash)

    print(time.time() - start)
    print("Your password: {}".format(result.decode('UTF-8')))


if __name__ == '__main__':
    main()
