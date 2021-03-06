---
title: Tetris Bot
date: '2021-05-11'
categories:
  - Games
tags:
  - Games
  - C++
---

[I made a Tetris bot](https://github.com/geranim0/tetris_bot_v2) that can play Tetris at more than 1 million blocks per second. To do that, I was inspired by someone who [made something similar to this](https://codemyroad.wordpress.com/2013/04/14/tetris-ai-the-near-perfect-player/) but it was running in javascript in the browser and it was really slow: took him about 2 weeks to clear 2 million lines, which is about 5 million blocks per 2 weeks. My bot, written in C++, is able to drop more than 1 million blocks per second.

First, I retook his approach of hand-crafting metrics to evaluate the value of a board, and then training the values using a Genetic Algorithm metaheuristic. For my version, I use 4 metrics:

1. Aggregate height. It's the sum of all heights of all columns in the board.
2. Lines destroyed by placing current block.
3. Holes. Number of holes in the current board.
4. Bumpiness. Sum of the absolute value of the differences between neighbor columns. 

Using the very simple to use Genetic Algorithm implementation found [here](https://github.com/olmallet81/GALGO-2.0), I then trained the weights for the 4 metrics, playing for 100,000 deaths and optimizing for total lines cleared in 100,000 deaths. It was really easy to setup thanks to its simple API. The only thing I had to modify is to be able to pass variadic arguments to its templates.

The weights are I obtained are {-7.41, 9.55, -9.366, -3.28 }. 

# Optimisation techniques

After that, all is left to do is create the most optimized possible tetris player. I did this by heavy use of templates, template metaprogramming, and new C++ features such as variants and tuples. I made everything that can be computable at compile time constexpr. That way, at runtime, everything goes as fast as possible. 

For example, the function that evaluates the board takes the board and a tetrimino, and evaluates all possible positions for that tetrimino, and returns the best board possible by placing that tetrimino. Since each tetrimino is known at compile-time (I made the tetriminos constexpr), each tetrimino is its own type. With this I was able to make the evaluation a template that specializes for each type of tetrimino, resulting in highly optimized evaluation function code for each tetrimino.

Another trick that I used to boost performance was careful engineering of the board representation. If we want to take advantage of bitwise operators, we have 2 options: using ints as colums or rows. In an earlier implementation (and much slower) I used ints as rows. It works okay for certain types of metrics, but the real problem with this is the line destruction. When we clear a line, it can be at any height. How to do this? If we use a vector, removing elements in the middle is O(n). Bad. Linked list? Indirection is too costly. I found the solution to this with the help of the IRC C community. 

At this point I already knew the limitations of ints as rows, so I was trying the ints as columns technique, but I could not figure out how to destroy a line efficiently. What we need is a way to, given a mask of full lines (which is easy to do in a single pass of the columns using bitwise operators), destroy every bit of every column where the (mask & 1) is true. Turns out, there is an instrinsic called "_pext" that does exactly that! Thanks IRC.

All the other metrics use carefully chosen intrinsics. I use "__builtin_clzll" which returns the position of the first bit set to true, and "__builtin_popcount" which returns the number of bits set to true. Both of these builtin functions are why this Tetris bot is going fast.

# Fun with template metaprogramming and constexpr

As a side note, when the bot was already going full speed, I had an itch about some copy pasta code in my iomplementation. 
At each iteration, we choose a random tetrimino, and call the evaluation function on the current board and that tetrimino. To do that I had a big switch with the same code in each case, the only thing that changed is the tetrimino I passed. But since each tetrimino is its own unique type, how to do this without using a switch? 
I was able to make the switch go away for a single function call using template metaprogramming. The way it works, is that I first generate a constexpr array of functors that take an std::variant of all tetriminos, and inside each functor the variant is compile-time resolved to its true type. After getting this array of functors, all we need to do is make a function that taken an index for the type of tetrimino, return the corresponding function in the array of functors, and call it with the correct parameters. Using this technique, I was able to delete my switch and my code duplication for a nice and simple 1-call function, and at 0 cost! I verified performance before and after, it is the same. The code generated is almost identical: with the switch the code generated was a jump table, and it is the exact same with the cleaner new implementation. We do a single jump in the array, and do the call. You can see my implementation of the compile-time functor array in the file "constexpr_func_arr.hpp". 

[Lien vers le bot](https://github.com/geranim0/tetris_bot_v2)