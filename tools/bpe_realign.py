#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals
from __future__ import print_function
from io import open
import re, argparse, json
from collections import defaultdict

'''

bpe_realign.py
Author: Pat Littell
Last Modified: July 31, 2017

This script takes 
  (a) a BPE-ified corpus text file and 
  (b) a line-by-line collection of graph edges 
and realigns and renames the graph edges.


Example input:
BPE: every@@ body like@@ d the ott@@ er
Edges: (1,0,ARG1) (1,3,ARG2)

Example output (with options --outer first and --inner head): 
  (2,0,ARG1_FIRST) (2,5,ARG2_FIRST) (0,1,BPE_FIRST) (1,0,BPE_OF_FIRST) (2,3,BPE_FIRST) (3,2,BPE_OF_FIRST) (5,6,BPE_FIRST) (6,5,BPE_OF_FIRST)
  
The possible options for --outer (i.e., the external edges between words) are:
  "first": The first BP in a word inherits its between-word edges
  "last": The last BP in a word inherits its between-word edges
  "longest": The longest BP in a word inherits its between-word edges
  "all" (default): All BPs in a word inherit its between-word edges
  
The possible options for --inner (i.e., the egdges within a word) are:
  "head": Every BP in a word is connected to the head of the word
  "neighbors" (default): Every BP in a word is connected to its left and right neighbors
  
These options can be combined with |, e.g. "first|last|all".
  
'''

def determine_bpe_mapping(bpe_str, head_strategy="all"):
    ''' Determine the one-to-many mapping between word indices and BP indices, and which BPs count as heads 
        for the purpose of re-indexing word-to-word mappings.  (E.g., does the first BP inherit the word's 
        edges?  The last?  All of them?) '''
    word_index = 0
    word_bpe_mapping = defaultdict(list)
    bpe_is_head = []
    longest_bpe_in_word = ''
    longest_bpe_in_word_index = -1
    
    for bpe_index, bpe in enumerate(bpe_str.split()):
    
        stripped_bpe = bpe.rstrip("@@")
        
        if len(stripped_bpe) > len(longest_bpe_in_word):
            longest_bpe_in_word = stripped_bpe
            longest_bpe_in_word_index = bpe_index
        
        is_head = False
        if head_strategy == "all":
            is_head = True
        elif head_strategy == "first" and not word_bpe_mapping[word_index]:
            is_head = True
        elif head_strategy == "last" and not bpe.endswith("@@"):
            is_head = True
            
            
        word_bpe_mapping[word_index].append(bpe_index)
        bpe_is_head.append(is_head)
        
        if not bpe.endswith("@@"):
            # it's the last BPE in the word
            if head_strategy == "longest":
                bpe_is_head[longest_bpe_in_word_index] = True
            longest_bpe_in_word = ''
            longest_bpe_in_word_index = -1
            word_index += 1
            
    return word_bpe_mapping, bpe_is_head
    

def parse_edges(edge_str, line_num=0):
    ''' Parse one line of edge descriptions into (source, dest, label) triples '''
    results = []
    for edge in re.findall(r'\((.*?)\)',edge_str):
        parts = edge.split(",")
        try:
            origin = int(parts[0])
            destination = int(parts[1])
            label = parts[2]
            results.append((origin, destination, label))
        except:
            print("ERROR: Edge malformed on line %s: %s" % (line_num, edge))
    return results
    
   
def align_outer(bpe_mapping, bpe_is_head, edges, line_num, outer_strategy="all", inner_strategy="neighbors", self_strategy=False):
    ''' Changes the indices of word-to-word edges so that they're BP-to-BP edges instead '''
    new_edges = set()
    new_edge_labels = set()
    for origin, destination, label in edges:
    
        if label.upper() == "SELF":  # don't realign SELF edges!
            continue
            
        new_label = label + "_" + outer_strategy.upper()
        if origin not in bpe_mapping:
            print("ERROR: Word index %s invalid on line %s" % (origin, line_num))
            continue
        if destination not in bpe_mapping:
            print("ERROR: Word index %s invalid on line %s" % (destination, line_num))
            continue
        
        new_edge_labels.add(new_label)
        for new_origin in bpe_mapping[origin]:
            for new_destination in bpe_mapping[destination]:
                if bpe_is_head[new_origin] and bpe_is_head[new_destination]:
                    new_edges.add((new_origin, new_destination, new_label))
    
    return new_edges, new_edge_labels

def align_inner(bpe_mapping, bpe_is_head, edges, line_num, outer_strategy="all", inner_strategy="neighbors", self_strategy=False):
    ''' Adds new BP-to-BP edges within a single word, in either a star ("head") or line ("neighbors") topology '''
    new_edges = set()
    if inner_strategy == 'head':
        label = "BPE_" + outer_strategy.upper()
        label_of = "BPE_OF_" + outer_strategy.upper()
        new_edge_labels = set([label, label_of])
        for word_index, bpe_indices in bpe_mapping.items():
            for origin_bpe_index in bpe_indices:
                if bpe_is_head[origin_bpe_index]:
                    for destination_bpe_index in bpe_mapping[word_index]:
                        if origin_bpe_index != destination_bpe_index:
                            new_edges.add((origin_bpe_index, destination_bpe_index, label))
                            new_edges.add((destination_bpe_index, origin_bpe_index, label_of))
    else:
        label_left = "BPE_LEFT"
        label_right = "BPE_RIGHT"
        new_edge_labels = set([label_left, label_right])
        for word_index, bpe_indices in bpe_mapping.items():
            for origin_bpe_index, destination_bpe_index in zip(bpe_indices, bpe_indices[1:]):
                new_edges.add((origin_bpe_index, destination_bpe_index, label_right))
                new_edges.add((destination_bpe_index, origin_bpe_index, label_left))       
                
    return new_edges, new_edge_labels

def align_self(bpe_mapping, bpe_is_head, edges, line_num, outer_strategy="all", inner_strategy="neighbors", self_strategy=False):
    ''' Add SELF edges for each BP '''
    new_edges = set()
    new_edge_labels = set()
    if self_strategy:
        new_edge_labels = set(["SELF"])
        for word_index, bpe_indices in bpe_mapping.items():
            for bpe_index in bpe_indices:
                new_edges.add((bpe_index, bpe_index, "SELF"))
    return new_edges, new_edge_labels
        
def process(bpe_filename, edges_filename, output_filename, output_map_filename, outer_strategies, inner_strategies, self_strategy):
    
    with open(bpe_filename, 'r', encoding="utf-8") as fin:
        bpe_lines = fin.readlines()
        
    with open(edges_filename, 'r', encoding="utf-8") as fin:
        edge_lines = fin.readlines()
        
    if len(bpe_lines) != len(edge_lines):
        print("FATAL ERROR: Different number of lines in BPE and edge files: %s vs %s" %
            (len(bpe_lines), len(edge_lines)))
        return
        
    edge_labels = set()
    with open(output_filename, 'w', encoding="utf-8") as fout:
        for i, (bpe_line, edge_line) in enumerate(zip(bpe_lines, edge_lines)):
            edges = set()
            for outer_strategy in outer_strategies.split("|"):
                for inner_strategy in inner_strategies.split("|"):
                    bpe_mapping, bpe_is_head = determine_bpe_mapping(bpe_line, outer_strategy)
                    old_edges = parse_edges(edge_line, i)
                    for aligner in [align_outer, align_inner, align_self]:
                        new_edges, new_edge_labels = aligner(bpe_mapping, bpe_is_head, 
                                                                                old_edges, i, outer_strategy, 
                                                                                inner_strategy, self_strategy)
                        edges.update(new_edges)
                        edge_labels.update(new_edge_labels)
                   
            new_edges_str = " ".join(("(%s,%s,%s)" % (o,d,l) for o,d,l in edges))
            fout.write(new_edges_str + "\n")
            
    with open(output_map_filename, 'w', encoding="utf-8") as fout:
        results = {label:i for i, label in enumerate(edge_labels)}
        fout.write(json.dumps(results, ensure_ascii=False, indent=2))
            
        
if __name__ == '__main__':
    argparser = argparse.ArgumentParser()
    argparser.add_argument("bpes", help="Byte-pair encoding lines")
    argparser.add_argument("edges", help="Edge triples (source,dest,label)")
    argparser.add_argument("output", help="Output file for new edge triples (source,dest,label)")
    argparser.add_argument("output_map", help="Output file for the label->integer mapping")
    argparser.add_argument("--outer", default="all", help="Which BPEs count as heads for realignment? (first, last, longest, all; can select multiple like first|last)")
    argparser.add_argument("--inner", default="neighbors", help="Within a word, to what BPEs are each BPE connected? (head, neighbors; can select both as head|neighbors)")
    argparser.add_argument('--self', dest='self_edges', action='store_true', help="Whether SELF edges should be added for each BP")
    argparser.add_argument('--no-self', dest='self_edges', action='store_false', help="'Now then, master Gotama, is there a self?' When this was said, the Blessed One was silent. 'Then is there no self?' The second time the Blessed One was silent.")
    argparser.set_defaults(self_edges=False)
    args = argparser.parse_args() 
    process(args.bpes, args.edges, args.output, args.output_map, args.outer, args.inner, args.self_edges)
    