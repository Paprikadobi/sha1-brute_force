from sha1 import sha1, to_hex, brute_force
import string
import time

chars = string.ascii_letters + string.digits + "@_!#$%^&*()<>?~:"

def main():
    print("Insert password: ")
    password = input()

    hash = sha1(password.encode())

    print("Hashed password: {}".format(to_hex(*hash)))

    start = time.time()
    
    result = brute_force(chars.encode(), *hash, min_length = 1, max_length = 6, num_threads = 4, buff_size = 78)

    print(time.time() - start)
    if result == -1:
        print("Password not found")
    else:
        print("Your password: {}".format(result.decode('UTF-8')))


if __name__ == '__main__':
    main()
