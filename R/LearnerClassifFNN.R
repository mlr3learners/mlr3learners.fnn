#' @title Classification Fast Nearest Neighbor Search Learner
#'
#' @name mlr_learners_classif.fnn
#'
#' @description
#' Classification fast nearest neighbor search learner.
#' Calls [FNN::knn()] from package \CRANpkg{FNN}.
#'
#' @templateVar id classif.fnn
#' @template section_dictionary_learner
#'
#' @export
#' @template seealso_learner
#' @template example
LearnerClassifFNN = R6Class("LearnerClassifFNN",
  inherit = LearnerClassif,
  public = list(

    #' @description
    #' Creates a new instance of this [R6][R6::R6Class] class.
    initialize = function() {
      ps = ParamSet$new(
        params = list(
          ParamInt$new(id = "k", default = 1, lower = 1L, tags = "train"),
          ParamFct$new(
            id = "algorithm", default = "kd_tree",
            levels = c("kd_tree", "cover_tree", "brute"), tags = "train"
          )
        )
      )

      super$initialize(
        id = "classif.fnn",
        packages = "FNN",
        feature_types = c("integer", "numeric"),
        predict_types = c("response", "prob"),
        param_set = ps,
        properties = c("twoclass", "multiclass"),
        man = "mlr3learners.fnn::mlr_learners_classif.fnn"
      )
    }
  ),

  private = list(
    .train = function(task) {
      list(
        data = task$data(),
        pars = self$param_set$get_values(tags = "train")
      )
    },

    .predict = function(task) {
      model = self$model
      train = model$data[, task$feature_names, with = FALSE]
      target = model$data[, task$target_names, with = FALSE][[1]]
      newdata = task$data(cols = task$feature_names)

      if (self$predict_type == "response") {
        p = invoke(FNN::knn,
          train = train, test = newdata, cl = target,
          .args = model$pars
        )
        PredictionClassif$new(task = task, response = p)
      } else {
        if (task$properties != "twoclass") {
          stop("Probabilities are not available for multiclass")
        }
        p = invoke(FNN::knn,
          train = train, test = newdata, cl = target,
          prob = TRUE, .args = model$pars
        )

        # Predicted probabilities refer to the winning class
        prob = attr(p, "prob")
        p = ifelse(p == task$positive, prob, 1 - prob)
        p = matrix(c(p, 1 - p), ncol = 2L, nrow = length(p))
        colnames(p) = task$class_names
        PredictionClassif$new(task = task, prob = p)
      }
    }
  )
)
