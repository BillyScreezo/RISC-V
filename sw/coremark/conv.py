import sys


def main(argv):
    fin = open(argv[0], "r")
    fout = open(argv[1], "w")

    for str in fin:
        if str[0] == '@':
            addr = int(str[1:], 16)
            if addr % 4 != 0:
                raise 'Address must be divisible by 4!'
            fout.write('@' + format(addr // 4, '08X') + '\n')
        else:
            fout.write(str)
    fout.close()
    fin.close()


if __name__ == '__main__':
    main(sys.argv[1:])
