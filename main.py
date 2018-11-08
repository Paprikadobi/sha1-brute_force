from sha1 import sha1, to_hex
import string

from Hack import Hack

chars = string.ascii_letters + string.digits + "@_!#$%^&*()<>?~:"

def main():
    print("Insert password: ")
    password = input()
    hash = sha1(b'%s' % str.encode(password))

    print("Hashed password: {}".format(to_hex(*hash)))

    obj = Hack(chars)
    result = obj.find_pass(hash)
    print("Your password: {}".format(result))


if __name__ == '__main__':
    main()
