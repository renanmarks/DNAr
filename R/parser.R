# DNAr is a program used to simulate formal Chemical Reaction Networks
# and the ones based on DNA.
# Copyright (C) 2017  Daniel Kneipp <danielv[at]dcc[dot]ufmg[dot]com[dot]br>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


#' Get the first part of a reaction.
#'
#' Given a reaction like 'A + B -> C', this function
#' returns 'A + B '.
get_first_part <- function(react_str) {
    return(sub('->.*', '', react_str))
}

#' Get the second part of a reaction.
#'
#' Given a reaction like 'A + B -> C', this function
#' returns ' C'.
get_second_part <- function(react_str) {
    return(sub('.*->', '', react_str))
}

#' Check if a reaction is bimolecular.
#'
#' Given a reaction, this functions checks if it is
#' a bimolecular reaction.
#'
#' @examples
#' DNAr:::is_bimolecular('2A -> B')     # Should return TRUE
#' DNAr:::is_bimolecular('A + B -> C')  # Should return TRUE
#' DNAr:::is_bimolecular('A -> B')      # Should return FALSE
is_bimolecular <- function(react_str) {
    first_part <- get_first_part(react_str)
    return(get_stoichiometry_part(first_part) == 2)
}

#' Check if a reaction is unimolecular.
#'
#' Given a reaction, this functions checks if it is
#' a unimolecular reaction.
#'
#' @examples
#' DNAr:::is_bimolecular('2A -> B')     # Should return FALSE
#' DNAr:::is_bimolecular('A + B -> C')  # Should return FALSE
#' DNAr:::is_bimolecular('A -> B')      # Should return TRUE
#' DNAr:::is_bimolecular('0 -> A')      # Should return FALSE
is_unimolecular <- function(react_str) {
    first_part <- get_first_part(react_str)
    return(get_stoichiometry_part(first_part) == 1)
}

#' Check if a reaction is of the degradation type
#'
#' Given a reaction string, this function checks if this
#' reaction is a degradation reaction.
#'
#' @param react_str  A string representing the reaction
#'
#' @return TRUE if the reaction is of degradation.
is_degradation <- function(react_str) {
    right_part <- get_second_part(react_str)
    return(isempty_part(right_part))
}

#' Check if a reaction is of the formation type
#'
#' Given a reaction string, this function checks if this
#' reaction is a formation reaction.
#'
#' @param react_str  A string representing the reaction
#'
#' @return TRUE if the reaction is of formation.
is_formation <- function(react_str) {
    left_part <- get_first_part(react_str)
    return(isempty_part(left_part))
}

#' Check if part of a reaction is equal to 0.
#'
#' This function is useful when you have a reaction and
#' you want to check if it is something like 'A -> 0' (something to nothing).
#' To do this you get the second part of the reaction with
#' \code{\link{get_second_part}()} and then use this function with the second
#' part as the parameter.
#'
#' @examples
#' sp <- DNAr:::get_second_part('A -> 0')
#' DNAr:::isempty_part(sp)  # Should return TRUE
isempty_part <- function(react_part) {
    return(!is.na(suppressWarnings(as.numeric(react_part))) &&
               as.numeric(react_part) == 0)
}

#' Get the count of occurrences of a given species in a reaction part.
#'
#' With the reaction part 'A + B ', for instance, and \code{one_species}
#' begin equal to 'A', this function would return 1. On the case of '2A ' it
#' would return 2.
get_onespecies_count <- function(one_species, reaction_part) {
    m <- gregexpr(
        paste('\\b[1-9]*', one_species, '\\b', sep = ''),
        reaction_part
    )
    matches <- regmatches(reaction_part, m)
    nums <- array(0, length(matches[[1]]))
    if(length(nums) > 0) {
        for(i in 1:length(nums)){
            nums[i] <- as.numeric(sub(one_species, '', matches[[1]][i]))
            if(is.na(nums[i])) {
                nums[i] <- 1
            }
        }
    }
    return(nums)
}

#' Get the stoichiometry of a specific species in a reaction.
#'
#' This function uses \code{\link{get_onespecies_count}()} in the left
#' and right part of a reaction to get the stoichiometry of a species
#' in a reaction.
#'
#' @return A list with \code{left_sto} being the stoichiometry of a
#' species in the left side of a reaction, and \code{right_sto} being
#' the same but for the right side of the reaction.
#'
#' @examples
#' # It should return list(left_sto = 1, right_sto = 2)
#' DNAr:::get_stoichiometry_onespecies('A', 'A + B -> 2A')
#' # It should return list(left_sto = 0, right_sto = 1)
#' DNAr:::get_stoichiometry_onespecies('A', 'B -> A + B')
get_stoichiometry_onespecies <- function(one_species, reaction) {
    f_p <- get_first_part(reaction)
    s_p <- get_second_part(reaction)

    f_p_n <- get_onespecies_count(one_species, f_p)
    s_p_n <- get_onespecies_count(one_species, s_p)

    r <- list(left_sto = sum(f_p_n), right_sto = sum(s_p_n))
    return(r)
}

#' It returns the stoichiometry of part of a reaction.
#'
#' This function is used when you want to know the count of molecules
#' in part of a reaction.
#'
#' @examples
#' DNAr:::get_stoichiometry_part('A + B ')  # It should return 2
#' DNAr:::get_stoichiometry_part('2A ')     # It should return 2
#' DNAr:::get_stoichiometry_part(' C')      # It should return 1
get_stoichiometry_part <- function(reaction_part) {
    matches <- stringr::str_match_all(reaction_part,
                                      '([1-9])*([a-zA-Z0-9_]+)')[[1]]
    count <- 0
    for(i in 1:dim(matches)[1]) {
        n <- as.numeric(matches[i,2])
        if(is.na(n)) {
            n <- 1
        }
        count <- count + n
    }
    return(count)
}

#' Get the stoichiometry of a reaction
#'
#' Use this function to get the stoichiometry of the left and
#' right part of a reaction.
#'
#' @return a list with left_sto and right_sto being the stoichiometry
#' of the left and right part respectively.
#'
#' @examples
#' # Returns list(left_sto = 2, right_sto = 1)
#' DNAr:::get_stoichiometry_all('A + B -> C')
#' # Returns list(left_sto = 1, right_sto = 2)
#' DNAr:::get_stoichiometry_all('A -> 2B')
get_stoichiometry_all <- function(reaction) {
    f_p <- get_first_part(reaction)
    s_p <- get_second_part(reaction)
    r <- list(left_sto = get_stoichiometry_part(f_p),
              right_sto = get_stoichiometry_part(s_p))
    return(r)
}

#' Remove the stoichiometry of a species string.
#'
#' Use this function to get rid of the stoichiometry of a
#' species string.
#'
#' @return The species string without the stoichiometry (number)
#' specifying the number of molecules
#'
#' @examples
#' DNAr:::remove_stoichiometry('2A')   # Returns 'A'
#' DNAr:::remove_stoichiometry('2A2')  # Returns 'A2', The other numbers
#'                                     # are considered part of the species name
remove_stoichiometry <- function(species) {
    no_sto_spec <- c()
    for(i in 1:length(species)) {
        s <- sub('^[1-9]*', '', species[i])
        no_sto_spec <- c(no_sto_spec, s)
    }
    return(no_sto_spec)
}

#' Get the species of a reaction part
#'
#' Given part of a reaction, this function returns
#' the species of it without the stoichiometry.
#'
#' The species name must starts with a letter or be 0 (for special degradation
#' and formation reactions).
#'
#' @param reaction_part  Left or right part of a reaction.
#'
#' @return  A vector with the species names. It will return an empty vector
#'          if there is no species (0 is considered a species) on the
#'          reaction or there is only bad formed names
#'
#' @examples
#' DNAr:::get_species('A + 2B')  # Should return c('A', 'B')
get_species <- function(reaction_part) {
    specs <- strsplit(reaction_part, '[^a-zA-Z0-9_]')[[1]]
    specs <- specs[specs != '']
    specs <- remove_stoichiometry(specs)

    # If there is a species with empty name (bad formed name), warn the user
    # and ignore the name
    for(spec in specs) {
        if(spec == '') {
            warning(
                paste('The reaction part \'', reaction_part, '\' has a bad',
                       'formed species name. Species names must start with',
                       'a letter or be 0 (for special degradation and',
                       'formation reactions). I\'m ignoring the species name')
            )
        }
    }
    specs <- specs[specs != '']

    return(specs)
}

#' Get the reactants of a given reaction
#'
#' This function returns the reactants of a reactions,
#' removing their stoichiometry.
#'
#' @examples
#' DNAr:::get_reactants('A + B -> C')  # Returns c('A', 'B')
#' DNAr:::get_reactants('2A -> B')     # Returns c('A')
get_reactants <- function(reaction) {
    f_p <- get_first_part(reaction)
    reactants <- get_species(f_p)
    return(reactants)
}

#' Get the products of a given reaction
#'
#' This function returns the products of a reactions,
#' removing their stoichiometry. If the reaction is of the type
#' 'A -> 0', '0' is returned as a species since it is considered
#' a special species.
#'
#' @examples
#' DNAr:::get_products('A + B -> C')   # Returns c('C')
#' DNAr:::get_products('2A -> B + C')  # Returns c('B', 'C')
#' DNAr:::get_products('A -> 0')       # Returns c('0')
get_products <- function(reaction) {
    s_p <- get_second_part(reaction)
    products <- get_species(s_p)
    return(products)
}

#' Check which species are reactants in a given reaction
#'
#' It is used to check which of the given species are
#' reactants in a reaction, returning a vector with the
#' species indexes in \code{species} that are reactants
#' in \code{reaction}.
#'
#' @return A vector filled with indexes specifying the
#' species that are in a reaction as a reactant.
#'
#' @examples
#' # Should return c(1, 2)
#' DNAr:::reactants_in_reaction(c('A', 'B', 'C'), 'A + B -> C')
#' # Should return c(1)
#' DNAr:::reactants_in_reaction(c('A', 'B', 'C'), '2A -> B + C')
#' # Should return c(1, 3)
#' DNAr:::reactants_in_reaction(c('A', 'B', 'C'), 'A + C -> B')
reactants_in_reaction <- function(species, reaction) {
    words <- get_reactants(reaction)
    r <- c()
    for(i in 1:length(species)) {
        if(any(words == species[i])) {
            r <- c(r, i)
        }
    }
    return(r)
}

#' Check if a CRN is respecting the limitations of the function
#' \code{\link{react}()}
#'
#' This function can be used to check the crn parameters passed to
#' \code{\link{react}()}. It checks:
#'  - If all the parameters are correctly defined
#' and of the correct type;
#'  - If the length of `species` and `reactions` are equal to the length
#' of `ci` and `ki`, respectively;
#'  - If there is no duplicate of species names on the `species` parameter.
#' The parameters of this function are the same of \code{\link{react}()}.
#'
#' @return  The reactions after the preprocessing made by
#'          `\link{check_fix_reaction}()` witch checks the reactions and fix
#'          them when it is possible.
check_crn <- function(species, ci, reactions, ki, t) {
    # Check if all parameters were set correctly
    # This is a helper function to check the parameters
    check_var <- function(vec, type_checker, err_msgs) {
        # Check if the vec parameter is if the type vector
        assertthat::assert_that(is.vector(species), msg = err_msg[[1]])

        # Check if all vector elements are of the correct type
        # using the type_checker function
        assertthat::assert_that(all(
                sapply(vec, function(x) type_checker(x))
        ), msg = err_msgs[[2]])
    }

    check_var(
        species,
        is.character,
        list('species parameter should be a vector',
             'All elements of species must be text')
    )
    check_var(
        ci,
        is.numeric,
        list('ci parameter should be a vector',
             'All elements of ci must be numbers')
    )
    check_var(
        reactions,
        is.character,
        list('reactions parameter should be a vector',
             'All elements of reactions must be text')
    )
    check_var(
        ki,
        is.numeric,
        list('ki parameter should be a vector',
             'All elements of ki must be numbers')
    )
    check_var(
        t,
        is.numeric,
        list('t parameter should be a vector',
             'All elements of t must be numbers')
    )

    # Check if there is any species duplicate
    assertthat::assert_that(
        !any(duplicated(species)),
        msg = 'species parameter has a duplicate element'
    )

    # Check if the length of species and ci are the same
    assertthat::assert_that(
        length(species) == length(ci),
        msg = 'The length of species and ci are not equal'
    )

    # Check if the length of reactions and ki are the same
    assertthat::assert_that(
        length(reactions) == length(ki),
        msg = 'The length of reactions and ki are not equal'
    )

    # Check the construction of each reaction
    new_reactions <- lapply(reactions, function(reaction) {
        check_fix_reaction(reaction)
    })

    return(new_reactions)
}

#' Helper function to concatenate strings
#'
#' this function should be used for string concatenation without
#' space between the strings as the default behavior.
#'
#' @param ...  The strings to be concatenated.
#'
#' @return  A string with all the input strings concatenated.
jn <- function(...) { paste(..., sep = '') }

#' Check and fix a reaction
#'
#' This function is used for the check and fix (if possible) of a reaction.
#' It is checked if there is an empty side, if both sides only contains
#' `0`'s, when the relation operator between sides (`->`) is missing. It also
#' fix the reactions that has a `0` with other species in the same side,
#' removing the 0 and warning the user.
#'
#' @param reaction  A string representing the reaction.
#'
#' @return  The fixed reaction if some fix was needed, or the
#'          reaction received as input if everything is ok.
check_fix_reaction <- function(reaction) {
    # Helper function to fix reactions with a 0 and other species
    # A + 0 ==> A; A + 2B + 0 => A + 2B
    fix_species_0 <- function(reaction_part) {
        species <- get_species(reaction_part)
        if(any(species == '0') && length(species) != 1) {
            return(stringr::str_replace_all(
                reaction_part,
                '\\+?\\s*0\\s*\\+?',
                ''
            ))
        } else {
            return(reaction_part)
        }
    }

    # Evaluate a reaction part
    eval_part <- function(get_part) {
        part <- get_part(reaction)

        # Check if the part only contain spaces
        assertthat::assert_that(
            trimws(part) != '',
            msg = paste('The reaction \'', reaction, '\' is bad formed.',
                        'It must have a left and right parts.')
        )

        new_part <- fix_species_0(part)
        list(new_part = new_part, changed = new_part != part)
    }

    # Check if there is a 0 and a species as reactants or products.
    # Constructions such as A + 0 are invalid and in this cases
    # the 0 will be removed
    eval_res_reactants <- eval_part(get_first_part)
    eval_res_products <- eval_part(get_second_part)

    # Check if the reactions has both sides 0
    assertthat::assert_that(
        !isempty_part(eval_res_reactants$new_part) ||
        !isempty_part(eval_res_products$new_part),
        msg = paste('Reaction \'', reaction, '\' is bad formed.',
                    'Both sides are 0.')
    )

    # Combine the new reaction parts
    new_reaction <- combine_reaction_parts(
        eval_res_reactants$new_part,
        eval_res_products$new_part,
        relation_operator(reaction)
    )

    # If some part has been changed, warn the user
    if(eval_res_products$changed || eval_res_reactants$changed) {
        warning(paste('The reaction \'', reaction, '\' is invalid. It is being',
                      'changed to \'', new_reaction, '\''))
    }

    return(new_reaction)
}

#' Gets the relation operator of the reaction
#'
#' The relation operator is the operator between two parts
#' of a reaction. Each reaction must have only one operator.
#' Currently, only the '->' operator is supported.
#'
#' @param reaction  A string representing a reaction.
#'
#' @return  A string which represents the relation operator of the reaction.
relation_operator <- function(reaction) {
    # Define the existent operators
    operators <- list('->')

    for (op in operators) {
        # If an operator str matched, returns it
        if(stringr::str_detect(reaction, op)) {
            return(op)
        }
    }

    # If no valid relation operator found
    stop(paste('The reaction \'', reaction, '\' does not have a valid relation',
               'operator'))
}

#' Combines two reaction parts to form a reaction
#'
#' This function combines two reaction parts and forms
#' a complete reaction construction with a reaction operator
#' which specifies the relation between the two parts.
#'
#' @param left_part   The first part of the reaction
#' @param right_part  The second part of the reaction
#' @param operator    A string specifying the relation between the parts.
#'                    It will be concatenated between the string parts.
#'
#' @return  A string representing the complete construction of a reaction.
combine_reaction_parts <- function(left_part, right_part, operator) {
    paste0(left_part, operator, right_part)
}

#' Function to expand species according to their stoichiometry
#'
#' This function expand a list of species according to the stoichiometry
#' of the species. E.g.: given a list of species `('A', 'B')` and
#' a stoichiometry of `A = 1` and `B = 2`, the resulting list
#' will be a list `('A', 'B', 'B')`.
#'
#' @param species        The list of species;
#' @param stoichiometry  A function that calculates the stoichiometry
#'                       of the species.
#'
#' @return  An expanded list of species.
expand_species <- function(species, stoichiometry) {
    unlist(
        lapply(species, function(s) {
            lapply(1:stoichiometry(s), function(i) {
                s
            })
        })
    )
}
