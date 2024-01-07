#########################################################################
# Network Analysis of Search Trajectory Networks (STN)
# Author: Gabriela Ochoa
# Date: January 2024
# Constructing STN Models for both single algorithms and merged model
# Version taking a single column as input
# Using modern data manipulation libraries
# Input:  Folder containing text file trace of runs, number of runs
# Output: STN graph objects - saved in given output folder 
#########################################################################
rm(list = ls(all = TRUE))
library(igraph)
library(tidyr)
library(dplyr)
library(data.table)

# Location of data files. Add here the folder containing  your data files
instance <- "pmed6"    # Indicate name of the instance/folder to process - This is folder with algorithm data

# It is then assumed that the instance data is in a directory called 'data'
infolder <- file.path("data", instance)  # input data
# The ouput models will be in a directory called 'stns'
outfolder <- file.path("stns", instance) # output stns
dir.create(outfolder, recursive = TRUE, showWarnings = FALSE)

bmin <- TRUE  # If TRUE minimization problem 
best <- NA    # Best fitness (cost) if known, otherwise is taken from input data
nruns <-10    # Number of runs

options(dplyr.summarise.inform = FALSE) # Remove summarise warnings
#-------------------------------------------------------------------------------
# Creates the STN of a given algorithm, and stores start and endes for merged model 
# Input:  algn: name of algorithm (ouput file)
# Uses:   Global structures nodes_all, edges_all, 
# Effect: Saves STN model in R data file

stn_create_alg <- function(algn)  {
  cat("Processing Algorithm: ", algn, "\n")
  df <- filter(nodes_all, Algorithm == algn)
  edges <- filter(edges_all, Algorithm == algn)
  snodes <- filter(start_nodes, Algorithm == algn)
  enodes <- filter(end_nodes, Algorithm == algn)
  start_ids <- unique(snodes$Solution)
  end_ids <- unique(enodes$Solution)      
  #------------------------------------------------------------------------------
  #  Nodes: Aggregating nodes with same Solution and Fitness
  #------------------------------------------------------------------------------
  df <- select(df,-Run) # Remove the Run column, not needed for constructing nodes
  nodes <- df %>%          # Field 'Counts' keeps frequency of apperance
    group_by(Fitness, Solution) %>%
    summarise(Count = n())
  # Assign Type of nodes -- There are 4 possible values
  # Start, End, Medium, Best - Default is Medium
  nodes$Type <- "Medium"
  begin_i <- which(nodes$Solution %in% start_ids)
  end_i <- which(nodes$Solution %in% end_ids)
  best_i <- which(nodes$Fitness == best)
  nodes[begin_i, "Type"] = "Start"
  nodes[end_i, "Type"] = "End"
  nodes[best_i,"Type"] = "Best"
  nodes <- relocate(nodes, Solution)  # Solutions as the first column for network construction
  cat("Number of nodes", nrow(nodes),"\n")
  #------------------------------------------------------------------------------
  #  Aggregating edges with same To: From:
  #-----------------------------------------------------------------------------
  edges <- edges%>%                # Keep unique edges with count for repetitions
    group_by(From, To) %>%
    summarise(Count = n())
  
  #-----------------------------------------------------------------------------
  #  Creation the STN model from the nodes and edges dataframes
  #-----------------------------------------------------------------------------
  STN <- graph_from_data_frame(edges, directed=TRUE, vertices=nodes)
  STN <- igraph::simplify(STN, remove.multiple = F, remove.loops = T)
  
 # Set Type of edges: Improving, Worsening, Equal - In terms of fitness
  el<-as_edgelist(STN)
  fits<-V(STN)$Fitness
  names<-V(STN)$name
  ## get the fitness values at each endpoint of an edge
  f1<-fits[match(el[,1],names)]
  f2<-fits[match(el[,2],names)]
  if (bmin) {  # minimisation problem 
    E(STN)[which(f2<f1)]$Type = "Improving"   # improving edges - Minimisation
    E(STN)[which(f2>f1)]$Type = "Worsening"   # worsening edges - Minimisation
  } else {
    E(STN)[which(f2>f1)]$Type = "Improving"   # improving edges - Maximisation
    E(STN)[which(f2<f1)]$Type = "Worsening"   # worsening edges - Maximisation
  }
  E(STN)[which(f2==f1)]$Type = "Neutral"  # equal fitness edges
  
  # Order node's Type for legend when plotting
  V(STN)$Type <- factor(V(STN)$Type, levels=c('Start', 'Medium', 'End', 'Best'))
  print("Node Types:")
  print(table(V(STN)$Type))
  print("Edge Types:")
  print(table(E(STN)$Type))
  foname <- paste0(instance,"_",algn, "_stn.RData")
  print(foname)
  save(best, worst, algn, bmin, instance, STN, file = file.path(outfolder,foname))  
}

#-------------------------------------------------------------------------------

# ---- Initialise required global data structures ------------------------------

# Dataframes to keep raw data of nodes and edges
nodes_all <- data.frame(Run = integer(), Fitness= numeric(), Solution = character(), Algorithm = character(),
                        stringsAsFactors=FALSE)
edges_all <- data.frame(From = character(), To = character(), Algorithm = character(),
                        stringsAsFactors=FALSE)

# Dataframes to keep start and end nodes per algorithm
start_nodes <- data.frame(Solution = character(), Algorithm = character(),
                        stringsAsFactors=FALSE)

end_nodes <- data.frame(Solution = character(), Algorithm = character(),
                          stringsAsFactors=FALSE)


alg_names <- list()      # List to keep names of algorithms

# ---- Process all files in the given input folder -----------------------------

data_files <- list.files(infolder)  # filenames in folder


# Creating a large data-frame with all runs of all algorithms
for (f in data_files) {
  df<- fread(file.path(infolder,f),stringsAsFactors = F)
  algn <- strsplit(f,"_")[[1]][1]   # name of the algorithm
  alg_names <- append(alg_names,algn)
  colnames(df) <- c("Run","Fitness","Solution")
  df <- filter(df, Run <= nruns) # Select number of desired runs
  df$Algorithm <- algn
  nodes_all<- rbind(nodes_all, df)  
  # Add edges separately per run, to avoid linking end of a run with start of the next
  for (r in 1:nruns) {
    dfr <- filter(df, Run == r)
    # Store the the start and ends of each run
    i <- nrow(start_nodes)+1 # index to append rows to start and nodes dataframes
    start_nodes[i,] <- c(dfr[1]$Solution, algn) #
    end_nodes[i,] <- c(dfr[nrow(dfr)]$Solution, algn)
    e <- dfr$Solution  # Solution to be used as signature for nodes in the edge list
    elist <- data.frame(From = e, To = dplyr::lead(e, 1, default = e[1]))
    elist <- elist[-c(nrow(elist)), ]   # remove last row, as it is adding dummy edge
    elist$Algorithm <- algn
    edges_all <- rbind(edges_all, elist)  # Collect all edges from all runs
  }
}  

remove(df, e, elist)  # Remove auxiliary variables from memory

# If best is not given, determine it from all files input trajectories
if (is.na(best)) {
  best <- ifelse(bmin, min(nodes_all$Fitness), max(nodes_all$Fitness))
  cat("Best value in data:", best, "\n")
}

# Save also the worst in case it is required for plotting purposes
worst <- ifelse(bmin, max(nodes_all$Fitness), min(nodes_all$Fitness))
# Create individual algorithm STNs
lapply(alg_names, stn_create_alg)

# Get the start and end nodes, convert to vector and remove duplication 
start_ids <- unique(start_nodes$Solution)
end_ids <- unique(end_nodes$Solution)       

# ------------------------------------------------------------------------------
#  Construct merged STN model 
#  Only if the number of algorithms in the folder is between 2 and  5
# ------------------------------------------------------------------------------
#  Nodes: Aggregating nodes with same Solution and Fitness
#-------------------------------------------------------------------------------
num_alg <- length(alg_names) 
cat("Number of Algorithms: ", num_alg, "\n")

if (num_alg > 1 & num_alg < 6 )  {
  cat("Creating the merged STN model for", num_alg, "algorithms \n" )
  # Create two new fields Count= sampling frequency, Algos: Concatenate visiting algorithms
  nodes <- nodes_all %>%          
    group_by(Fitness, Solution) %>%
    summarise(Count = n(), 
              Algos = paste(Algorithm, collapse = "_") )
  
  # Remove repetitions from Algos, so each visited algorithm is shown once
  salg <- sapply(nodes$Algos, function(l) paste(unique(unlist(strsplit(l,"_"))), collapse = "_")  )
  nodes$Algos <- salg # With removed duplications
  # Indicate "Shared" for solutions visited by more than one algorithm
  salg <- sapply(unname(salg), function(l) fifelse(l %in% alg_names, l, "Shared"))
  nodes$Type <- salg
  # Assign special type of Nodes
  begin_i <- which(nodes$Solution %in% start_ids)
  end_i <- which(nodes$Solution %in% end_ids)
  best_i <- which(nodes$Fitness == best)
  nodes[begin_i, "Type"] = "Start"
  nodes[end_i, "Type"] = "End"
  nodes[ best_i,"Type"] = "Best"
  nodes <- relocate(nodes, Solution)  # Solutions as the first column for network construction
  cat("Number of nodes Merged Model", nrow(nodes),"\n")
  
  #-------------------------------------------------------------------------------
  #  Edges: Aggregating edges with same To: From:
  #-------------------------------------------------------------------------------
  # Create two new fields Count= sampling frequency, Algos: Concatenate visiting algorithms
  
  edges <- edges_all%>%                
    group_by(From, To) %>%
    summarise(Count = n(),  
              Algos = paste(Algorithm, collapse = "_") )
  
  # Remove repetitions from Algos, so each visited algorithm is shown once
  salg <- sapply(edges$Algos, function(l) paste(unique(unlist(strsplit(l,"_"))), collapse = "_")  )
  edges$Algos <- salg # With removed duplications
  # Indicate "Shared" for solutions visited by more than one algorithm
  salg <- sapply(unname(salg), function(l) fifelse(l %in% alg_names, l, "Shared"))
  edges$Algorithms <- salg
  
  #------------------------------------------------------------------------------
  #  Creation the STN merged model from the nodes and edges dataframes
  #------------------------------------------------------------------------------
  STNm <- graph_from_data_frame(edges, directed=TRUE, vertices=nodes)
  STNm <- igraph::simplify(STNm, remove.multiple = F, remove.loops = T)
  
  # Order node Type for legend when plotting
  V(STNm)$Type <- factor(V(STNm)$Type, levels=c('Start', 'End', 'Best', array(unlist(alg_names)), 'Shared') )
  print("Nodes Types in Merged STN")
  print(table(V(STNm)$Type))
  
  foname <- paste0(instance, "_merged_stn.RData")
  print(foname)
  save(best, worst, alg_names, num_alg, instance, STNm, file = file.path("stns",foname))  

} else {
  cat("Merged model not created as the numner of algorithms", num_alg, "is not in the required range [2,5] \n" )
}
