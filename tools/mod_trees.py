
import nltk
import sys

INPUT = sys.argv[1]
MODE = sys.argv[2]
if MODE == 'bpe':
    BPE_FILE = sys.argv[3]

def print_tree(tree, mode='all', bpe=None):
    to_print = []

    def print_node(node, mode='all'):
        if mode == 'all':
            # terminal
            if type(node) == str:
                to_print.append(node)
            elif len(node) == 0:
                to_print.append(node.label())
                
            # non-terminal
            else:
                to_print.append(node.label() + '(')
                for child in node:
                    print_node(child, mode)
                to_print.append(')')
        elif mode == 'bpe':
            # terminal
            if type(node) == str:
                while True:
                    #try:
                    next_subword = bpe.pop(0)
                    #except IndexError:
                    #next_subword = ' '
                    to_print.append(next_subword)
                    if not next_subword.endswith('@@'):
                        break
            elif len(node) == 0:
                to_print.append(node.label())
                
            # non-terminal
            else:
                to_print.append(node.label() + '(')
                for child in node:
                    print_node(child, mode)
                to_print.append(')')

        elif mode == 'noleaves':
            # pre-terminal
            if len(node) == 1 and (type(node[0]) == str or len(node[0]) == 0):
                to_print.append(node.label())
            # non-pre-terminal
            else:
                to_print.append(node.label() + '(')
                for child in node:
                    print_node(child, mode)
                to_print.append(')')
    print_node(tree, mode)
    return ' '.join(to_print)

if MODE == 'bpe':
    with open(BPE_FILE) as f:
        bpe = f.readlines()
else:
    bpe = None

with open(INPUT) as f:
    i = 0
    for line in f:
        i += 1
        #print(i)
        #print(line)
        try:
            tree = nltk.tree.Tree.fromstring(line)
        except ValueError:
            #line = line.replace('()', '')
            #tree = nltk.tree.Tree.fromstring(line)
            try:
                tree = nltk.tree.Tree.fromstring(line + ')')
                #tree = nltk.tree.Tree.fromstring(line)
            except ValueError:
                #print(line)
                #raise
                try:
                    tree = nltk.tree.Tree.fromstring(line.strip()[:-1])
                except ValueError:
                    try:
                        tree = nltk.tree.Tree.fromstring(line.strip()[:-2])
                    except ValueError:
                        line = list(line.strip())
                        line[615] = ' '
                        line[614] = ' '
                        line[792] = ' '
                        line[800] = ' '
                        line = ''.join(line)
                        tree = nltk.tree.Tree.fromstring(line)
        if MODE == 'bpe':
            print(print_tree(tree, MODE, bpe[i-1].split()))
        else:
            print(print_tree(tree, MODE))
