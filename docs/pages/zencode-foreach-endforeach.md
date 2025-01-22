
# Looping: Foreach/EndForeach statements

Zenroom allows looping, done using the **Foreach** and **EndForeach** statements.
There are few possible way of looping that are:
* over an array
```gherkin
Foreach 'element' in 'array'
```
* over two or multiple arrays in parallel
```gherkin
# two arrays
Foreach value prefix 'loop variable ' at same position in arrays 'first array' and 'second array'
# equal to
Foreach value prefix 'loop variable ' across arrays 'first array' and 'second array'
# multiple arrays
Foreach value prefix 'loop variable ' at same position in arrays 'list of array names'
# equal to
Foreach value prefix 'loop variable ' across arrays 'list of array names'
```
* or from a number to another with certain step
```gherkin
Foreach 'i' in sequence from 'zero' to 'ten' with step 'one'
```

As can be seen the keyword **Foreach** is the one that indicates the start of a loop, while
the statement **EndForeach** indicates the ends of loop.
When reaching it if the condition of the foreach is still valid the loop is performed again.

Inside a **Foreach** you can use:
* **Foreach** statements (any of them must have a corresponding **EndForeach**)
* [**If**](zencode-if-endif) statements that must be closed before the loop end. Morever, even if the basic **If** support
the use of **Then** in it, when it is inside a loop this last property is not true anymore, only **When** statements can be used.
* [**When**](zencode-cookbook-when) statements

## Simple Foreach/EndForeach example

In the following script we are looping over all the elements of an array and simply copying them into a new one.

[](../_media/examples/zencode_cookbook/foreach/verysimple.zen ':include :type=code gherkin')

Indeed if run with data

[](../_media/examples/zencode_cookbook/foreach/verysimple.data ':include :type=code json')

the result will be

[](../_media/examples/zencode_cookbook/foreach/verysimple.out ':include :type=code json')

## Parallel Foreach over multiple arrays

Parallel loops allow you to iterate over multiple arrays simultaneously, processing corresponding
elements from each array in parallel. The loop ends as soon as the shortest array is exhausted,
ensuring that you only process elements up to the point where all arrays have corresponding values.
This feature is useful when you need to combine or process elements from multiple arrays that are structured similarly.

### Parallel Foreach over two arrays

If you want to loop over two arrays, let's say

[](../_media/examples/zencode_cookbook/foreach/docs_parallel.data.json ':include :type=code json')

at the same time you can use the following syntax:

[](../_media/examples/zencode_cookbook/foreach/docs_parallel.zen ':include :type=code gherkin')

In this simple code we just concatenated the values in `x` and `y` arrays that occupies the same position, indeed the result is

[](../_media/examples/zencode_cookbook/foreach/docs_parallel.out ':include :type=code json')

### Parallel Foreach over multiple arrays

When iterating over three or more arrays, you can extend the same logic by referencing an additional array
that holds the names of the arrays you want to loop over.

Let's change a bit the above example to concatenate the values that occupies the same position in three 
different arrays. The data in input will be

[](../_media/examples/zencode_cookbook/foreach/docs_parallel_multiple.data.json ':include :type=code json')

where `arrays` is the string array containing the names of the array on which we want to iterate. The zencode will be

[](../_media/examples/zencode_cookbook/foreach/docs_parallel_multiple.zen ':include :type=code gherkin')

that would result in

[](../_media/examples/zencode_cookbook/foreach/docs_parallel_multiple.out ':include :type=code json')

## Break from a Foreach loop

The
```gherkin
When I break the foreach
# or equivalently
When I exit the foreach
```
statements allow you to exit a foreach loop prematurely. When executed, it immediately terminates the loop's iteration, skipping
any remaining items in the collection or sequence. The program then continues with the first statement following the loop.

The break statement is typically used when a specific condition is met within the loop,
and further iteration is unnecessary or undesirable. An example to understand the foreach and the break can be the following:

Display only those numbers from the list:

[](../_media/examples/zencode_cookbook/educational/foreach_divisible_by_five.data.json ':include :type=code json')

that satisfy the following conditions:
1. The number must be divisible by five
1. If the number is greater than 150, then skip it and move to the following number
1. If the number is greater than 500, then stop the loop

We start by defineing some usefull variables in a file that we will use as keys file

[](../_media/examples/zencode_cookbook/educational/foreach_divisible_by_five.keys.json ':include :type=code json')

then the code will be

[](../_media/examples/zencode_cookbook/educational/foreach_divisible_by_five.zen ':include :type=code gherkin')

resulting in

[](../_media/examples/zencode_cookbook/educational/foreach_divisible_by_five.out.json ':include :type=code json')

## More complex Foreach/EndForeach example

You can play with them as much as you want, like:

[](../_media/examples/zencode_cookbook/branching/nested_if_in_foreach.zen ':include :type=code gherkin')

that with input data

[](../_media/examples/zencode_cookbook/branching/nested_if_in_foreach.data.json ':include :type=code json')

will result in

[](../_media/examples/zencode_cookbook/branching/nested_if_in_foreach.out.json ':include :type=code json')

# The script used to create the material in this page

All the smart contracts and the data you see in this page are generated by the scripts [branching.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/branching.bats),
[foreach.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/foreach.bats) and
[branching.bats](https://github.com/dyne/Zenroom/blob/master/test/zencode/educational.bats).
If you want to run the scripts (on Linux) you should:
 - *git clone https://github.com/dyne/Zenroom.git*
 - install  **jq**
 - download a [zenroom binary](https://zenroom.org/#downloads) and place it */bin* or */usr/bin* or in *./Zenroom/src*
