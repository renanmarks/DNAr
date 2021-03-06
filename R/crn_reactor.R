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


#' Returns the matrix M.
#'
#' The matrix M is used for the calculations made on \code{\link{react}()}.
#' This matrix  has #lines = #reactions and #columns = #species and it
#' represents the stoichiometry of each species at each reaction.
#'
#' @return A list with the named indexes `prod` (stoichiometry matrix of the
#'         products), `react` (stoichiometry matrix of reactants) and `M`
#'         (the M matrix generate from the difference of theses two matrices).
get_M <- function(reactions, species) {
    products <- matrix(data = 0,
                       nrow = length(reactions),
                       ncol = length(species))
    reactants <- matrix(data = 0,
                        nrow = length(reactions),
                        ncol = length(species))

    for(i in 1:length(reactions)) {
        for(j in 1:length(species)) {
            stoc <- get_stoichiometry_onespecies(species[j], reactions[i])
            products[i,j] <- stoc$right_sto
            reactants[i,j] <- stoc$left_sto
        }
    }

    M <- products - reactants
    data <- list(prod = products, react = reactants, M = M)
    return(data)
}

#' Simulate a CRN
#'
#' This is the function used to actually simulate the chemical reaction network.
#' Given the CRN specifications, it returns the behavior of the reaction.
#'
#' @section Known limitations:
#'   \itemize{
#'     \item It only supports uni or bimolecular reactions;
#'     \item Bidirectional reactions (e.g.: 'A <--> B') are not supported
#'   yet (you have to describe them with two separated reactions).
#'   }
#'
#' @param species    A vector with the species of the reaction. The order of
#'                   this vector is important because it will define the
#'                   column order of the returned behavior.
#' @param ci         A vector specifying the initial concentrations of the
#'                   \code{species} specified, in order.
#' @param reactions  A vector with the reactions of the CRN. If a reaction has
#'                   has only reactants that are non in `species`, this
#'                   reaction will be treated as `0 -> products`. Furthermore,
#'                   this function treats a reaction `non_registered_species
#'                   + registered_species -> products` equally to
#'                   `registered_species -> products`, ignoring the species non
#'                   registered on the `species` vector.
#' @param ki         A vector defining the constant rate of each reaction
#'                   in \code{reactions}, in order.
#' @param t          A vector specifying the time interval. Each value
#'                   would be a specific time point.
#' @param verbose    Be verbose and print information about the integration
#'                   process with `deSolve::diagnostics.deSolve()`. Default
#'                   value is `FALSE`
#' @param ...        Parameters passed to `deSolve::ode()`.
#'
#' @return A data frame with each line being a specific point in the time
#'         and each column but the first being the concentration of a
#'         species. The first column is the time interval. The column names
#'         are filled with the species's names.
#'
#' @export
#'
#' @example demo/main_crn.R
react <- function(species, ci, reactions, ki, t, verbose = FALSE, ...) {
    # Check the crn specification
    reactions <- check_crn(species, ci, reactions, ki, t)

    # Get stoichiometry information
    sto_info <- get_M(reactions, species)
    sto_react <- t(sto_info$react)
    Mt <- t(sto_info$M)

    # Matrix that works as a map, specifying the reactants
    # of each reaction.
    reactant_map <- lapply(reactions, function(reaction) {
        r_map <- reactants_in_reaction(species, reaction)
        if(is.null(r_map)) {
            # Return NA instead of NULL because NA^0 = 1
            return(NA)
        } else {
            return(r_map)
        }
    })

    # If a species A is consumed n times in a reaction,
    # the speed of the reaction will be -k[A]^n
    v_exp_reactants <- lapply(seq_along(reactant_map), function(i) {
        # Get the stoichiometry info of the reactant for each reaction
        if(length(reactant_map[[i]]) > 1 || !is.na(reactant_map[[i]])) {
            return(sto_react[reactant_map[[i]], i])
        } else {
            return(0)
        }
    })

    # Define function for deSolve
    fx <- function(t, y, parms) {
        # Define the vector, which specifies the impact magnitude of
        # each reaction
        v <- matrix(mapply(function(react_map, k, v_exp) {
            vi <- k * prod(y[react_map]^v_exp)
        }, reactant_map, ki, v_exp_reactants))

        # Multiply the impact magnitude of each reaction with the stoichiometry
        # of each species to get the new species concentrations
        dy <- Mt %*% v

        list(dy)
    }

    result <- deSolve::ode(times = t, y = ci, func = fx, parms = NULL, ...)
    if(verbose) {
        print(deSolve::diagnostics.deSolve(result))
    }

    # Convert double matrix to dataframe
    df_result <- data.frame(result)
    names(df_result) <- c('time', species)

    return(df_result)
}

#' Combine CRNs into one single larger CRN
#'
#' Use this function to combine multiple crns into a larger crn which
#' has all the reactions, species and other parameters of all other CRNs.
#'
#' @param crns  List of CRNs.
#'
#' @return  Another CRN representing the input CRNs combined
#'
#' @export
combine_crns <- function(crns) {
    # Initialize the parameters
    parms <- list(
        species   = c(),
        ci        = c(),
        reactions = c(),
        ki        = c()
    )

    # Combine the CRNs
    for(crn in crns) {
        parms$species   <- c(parms$species, crn$species)
        parms$ci        <- c(parms$ci, crn$ci)
        parms$reactions <- c(parms$reactions, crn$reactions)
        parms$ki        <- c(parms$ki, crn$ki)
    }

    return(parms)
}
