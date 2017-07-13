import sys

FILENAME = sys.argv[1]

with open(FILENAME) as f:
    to_print = False
    for line in f:
        # Ignore empty lines
        if line.strip() == '':
            continue
        # Preamble starts with URL
        if line.startswith('http://'):
            to_print = False                        
        if to_print:
            print(line.strip())
        # Second-to-last line of the preamble is a digit
        # Last line is the talk's title, we keep this
        if line.split()[0].isdigit() and line.split()[1].isdigit():
            to_print = True
