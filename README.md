# STNs-v2: Search Trajectory Networks v2

STNs are a modelling and visualisation tool for understanding the dynamics of metaherustics, including evolutionary algorithms. They can, in principle, be applied to both combinatorial and continuous optimisation problems, as well as to more complex representations in neuroevolution.

This repository contains [R](https://cran.r-project.org/) scripts for constructing STNs from a simplified input data (a single solution recorded per line) and using more powerful data science R libraries, as compared to the first version of [this tool](https://github.com/gabro8a/STNs). It allows producing merged STN models of up to 5 algorihtms, while the previous version was restricted to a maximum of 3.

We also provide scripts for visualising STNs for single algorithms as well as merged STN models using newer visualisation libraries, and providing a novel graph layout that uses fitness (objective values) as the *Y* coordinate. This gives a complementary view to the force-directed and tree-based graph layouts previously used. Using the *Y* coordinate for fitness intuitively depicts the search process starting from low quality solutions and progressing towards high-quality ones. Both minimisation and maximisation problems can be modelled.

### Main STNs Articles

- Gabriela Ochoa, Katherine Malan, Christian Blum (2021) [Search trajectory networks](https://doi.org/10.1016/j.asoc.2021.107492): A tool for analysing and visualising the behaviour of metaheuristics, *Applied Soft Computing*, Elsevier.
- Camilo Chacón Sartori, Christian Blum, Gabriela Ochoa (2023) [STNWeb](https://doi.org/10.1016/j.simpa.2023.100558): A new visualization tool for analyzing optimization algorithms, *Software Impacts*, Volume 17,2023, 100558, 

### Dependencies

The scripts provided in this repository, make use of the following R libraries: 
- [igraph](https://igraph.org/r/): network analysis tools with emphasis on efficiency, portability and ease of use.
- [tidyr](https://tidyr.tidyverse.org/): tools to help you create *tidy* data (where every column is a variable, each row an observation and each cell a single value. 
- [dplyr](https://dplyr.tidyverse.org/):  a grammar of data manipulation, providing a consistent set of verbs that help you solve the most common data manipulation challenges.
- [data.table](https://cran.r-project.org/web/packages/data.table/index.html): provides a high-performance version of base R’s data.frame with syntax and feature enhancements for ease of use, convenience and programming speed.
- [ggraph](https://ggraph.data-imaginist.com/):is an extension of `ggplot2` aimed at supporting relational data structures such as networks, graphs, and trees.
- [ggpubr](https://rpkgs.datanovia.com/ggpubr/): provides some easy-to-use functions for creating and customising `ggplot2`- based publication ready plots.

You need to install the libraries above before running the scripts provided. We suggest using [RStudio](https://posit.co/download/rstudio-desktop/)to run the scripts and edit them as required to include your data and other arguments. We are not providing a command line interface like we did in the former version of this tool.
 

-------------------------------------------------------------------------------------------------------

## Input Data

We provide two sub-folders (`pmed6` and `pmed7`, within the `data` folder) with examples of input files for two instances of a combinatorial optimisation problem (the *p-median* problem).  The `pmed6` folder has 2 files, whereas `pmed7` has 3 files, each corresponding to a different metaheuristic algorithm. Each file contains the trajectory logs of 10 runs of a single instance-algorithm pair.  


A naming convention is required for the input files, where the first part of the name indicates the algorithm. For example, the files in the `pmed6` folder are: `aco_out.txt` and `brkga_out.txt`.

The input files can be formatted as either space/tab separated or comma-separated files. If comma separated files are used, their extension should be .`csv`. For space/tab separated files, any other file extension can be used (such as `.txt` or `.out).` You can have a header describing the columns, but it is also OK not to have it.

The files report a list of solutions in the search space in the order they were encountered during the search process. Each line contains the number of the run, followed by the fitness value and the signature of the representative solution at each iteration.

Let us consider the simple example of the *Onemax* problem for solutions of length 10. Remember the Onemax problem maximises the number of ones in a bit-string. The search space consists of binary strings of length 10, and fitness is an integer value counting the number of ones in the string. The format of the input files for a metaheuristic solving this problem would be as follows: 

| Run  | Fitness | Solution   | 
| ---- | ------- | ---------- | 
| 1    | 5       | 0101100011 | 
| 1    | 6       | 0101101011 | 
| ...  | ...     | ...        | 
| 10   | 3       | 0010010100 | 
| 10   | 8       | 1101111101 | 

Where **Run** is the run number (recall that several runs are used to construct an STN model), and the output of all runs of a given algorithm are kept in a single file. For each step in the trajectory,  **Fitness**  and **Solution** are the fitness value and signature, respectively, of the representative solution at each iteration.

For discrete representations such as binary strings, permutations, or integer representations; the signature of a location can be a string directly derived from the solution encoding (adding separators if required).  However, for continuous encodings or other complex representations, a mapping between the solution encoding and a string representing the location signature is required. There are different ways of implement such mapping. This repository does not currently contain scripts for mapping or partitioning the search space into location signatures. This will be the subject of future work. 

-------------------------------------------------------------------------------------------------------

## Creating the STN Models 

A single script `create.R` is provided to create both separate algorithms STNs and a merged STN model when data for number of algorithms (between 2 and 5) is given. 

### create.R

Creates the STN models of single algorithms from input data (given in an input folder) and saves the models as `.RData` files in an output sub-folder, within a folder called `stns`. A merged STN model model is also created combining the given algorithms.


In order to run the script, you need to edit the file to indicate one required  argument and three optional arguments: 

- `instance`[*Required*] A string indicating the folder containing the input data files with algorithm(s) runs for a given problem instance. 
- `nruns` [*Optional*] An integer indicating the number of runs from the input files to be used. This should be a number between 1 up to total number of runs within in the raw data files. If no argument is given, the largest run number in the collection of input files is used. 
- `best`[*Optional*] The objective value of the global optimum (or best-known solution)  of the instance considered [*Optional*],  with the desired precision in case of real valued functions.  If no argument is given, the best evaluation value in the whole collection of input files is used.
- `bmin`[*Optional*] A Boolean  indicating minimisation (TRUE) or maximisation (FALSE). If no argument is given, minimisation (i.e TRUE) is assumed.


Running the script will create a folder `stns`, and within it a subfolder with the name of the input (instance) folder. The subfolder will contain the STN models of the input algorithms, stored in `.RData` files, one file per algorithm. The merged model will also be created as an `.RData` file within the `stns` folder.

-------------------------------------------------------------------------------------------------
## Visualising the STN Models

### gplot-single.R


Creates plots for each STN model (for single algorithms). It produces `.png` files with plots, which are stored in the `plots` folder. 

The script requires one argument and a second optional argument:


- `instance`[*Required*] A string indicating the folder containing the STN `.RData` files previously created with the `create.R` script
- `size_range` [*Optional*] A pair of numbers indicating the a range to scale the size of nodes. The default value for this parameter is  `c(1, 5)`. Real number scan be used.  for example `c(2.5, 5.3)`.

Running the script will create a folder `plots`, and within it, a subfolder with the name of the input folder. The subfolder will contain `.png` files plotting the STN models of the input algorithms, one file per algorithm. Each file contains two sub-plots, the left sub-plot uses the [force-directed graph layout](https://en.wikipedia.org/wiki/Force-directed_graph_drawing) named  Kamada-Kawai (KK), while the right sub-plot takes the KK layout but forces the *Y* coordinate to indicate the nodes fitness value.


### gplot-merged.R

Creates plots  for the merged STN model of a given instance. It produces a `.png` file, which is stored in the `plots` folder.

The script requires one argument and a second optional argument:

- `instance`[*Required*] A string indicating the name of the instance. Notice that a file with the naming convention `instance_merged_stn.RData` containing the merged STN model should have been previously created with the `create.R` script
- `size_range` [*Optional*] A pair of numbers indicating the a range to scale the size of nodes. The default value for this parameter is  `c(1, 5)`. Real number scan be used.  for example `c(1.5, 4.3)`.

Running the script will create a folder `plots` (if it doesn't exist), and within it a `.png` file plotting the merged STN model of the given instance. The file contains two sub-plots, the left sub-plot uses the [force-directed graph layout](https://en.wikipedia.org/wiki/Force-directed_graph_drawing) named  Kamada-Kawai (KK), while the right sub-plot takes the KK layout but forces the *Y* coordinate to indicate the nodes fitness value.

-------------------------------------------------------------------------------------------------
## Computing STNs metrics

(Not ready yet, to be completed soon)


