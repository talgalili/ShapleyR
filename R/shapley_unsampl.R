#' Calculates the exact shapley value for every player based
#' on the algorithm for cooperative game theory.
#'
#' @description Calculates the exact shapley value for every player.
#' If you have N features/ players, there must be 2ˆN-1 rows in data.input. You can
#' leave the zero coalation away. Every row must be unique.
#' Below you can see an examle data input:
#' test.data = as.data.frame(rbind(c(1, 0, 5), c(0, 1, 4),c(1, 1, 10)))
#' name(test.data) = c("A", "B", "value")
#' And here with zero coalation:
#' test.data = as.data.frame(rbind(c(0, 0, 0), c(1, 0, 5), c(0, 1, 4),c(1, 1, 10)))
#' Player A has a coalation value of 5. Player A and B have a coalation value of 10.
#' @param data.input
#' @param target Put there the name of column with the results of the coalation-function.
#' @export
##Asserts, Permutation and iteration through player
shapley.unsampled = function(data.input = test, target = "value") {
  ##Assert
  assert_data_frame(data.input)
  assert_numeric(data.input[,target])

  df = data.input[,!(names(data.input) %in% target)] #coalations without target variable
  stopifnot(all(sapply(df, function(x) x == FALSE | x == TRUE))) #Only logical in df
  #Check expected row number (with/without empty coalation)
  if(0 %in% rowSums(df)){
    assert_data_frame(df, nrows = 2^ncol(df))
  }
  else
    assert_data_frame(df, nrows = 2^ncol(df)-1)
  stopifnot(identical(df, unique(df))) #Check uniqueness = every coalation once in data

  ##Permutations
  players = paste0("V", seq(1,ncol(df))) #Change names of columns to letters, so sort() works for any name
  S = permn(players) #Find all permutations of players
  ##Calculate Shapley
  shapley.calc = function(observed, S){
    sh.diff = c()
    for(i in 1:length(S)){
      index = grep(pattern = observed, x = S[[i]])
      #Choose players before/with observed player, No coalation = NA
      player.with = c(S[[i]][1:index])
      if(index != 1){
        player.before = c(S[[i]][1:(index-1)])
      }
      else
        player.before = NA
      #Target value of coalations
      for(j in 1:nrow(df)){
        curr.coal = c(players[df[j,] == 1])
        if(length(curr.coal)==length(player.with) && all(sort(curr.coal)==sort(player.with))){
          target.with = data.input$value[j]
        }
        if(length(player.before)==1 && is.na(player.before)){
          target.before = 0
        }
        if(length(curr.coal)==length(player.before) && all(sort(curr.coal)==sort(player.before))){
          target.before = data.input$value[j]
        }
      }
      #Substract the value of coalations
      sh.diff = append(sh.diff, target.with - target.before)
    }
    return(mean(sh.diff))
  }

  ##Create result
  sh.all = as.data.frame(matrix(data = 0, ncol = ncol(df), nrow = 1))
  names(sh.all) = names(df)
  for (player in players){
    column.index = grep(pattern = player, x = players) #from letters back to original column names
    sh.all[,column.index] = shapley.calc(observed = player, S = S)
  }
  return(sh.all)
}
