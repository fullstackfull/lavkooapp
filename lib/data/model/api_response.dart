
class ApiResponseModel<T> {
  final T? response;
  final dynamic error;
  final bool isSuccess;

  /// True when the request never received an answer: a timeout, a dropped connection, a request
  /// that was cancelled.
  ///
  /// This is not the same as a failure, and for anything that moves money or creates an order it
  /// must not be treated as one. A place-order call that times out may well have created the order:
  /// the server commits before it finishes talking to the courier, which can take 30 seconds per
  /// vendor, and the app gives up at 60. Telling the customer it failed is what produces the second
  /// order, the second stock decrement and the second COD collection.
  ///
  /// Defaults to false, so every existing caller reads exactly as it did before.
  final bool unanswered;

  ApiResponseModel(this.response, this.error, this.isSuccess, {this.unanswered = false});

  ApiResponseModel.withError(dynamic errorValue, {T? responseValue, this.unanswered = false})
      : response = responseValue,
        error = errorValue,
        isSuccess = false;

  ApiResponseModel.withSuccess(T? responseValue)
      : response = responseValue,
        error = null,
        isSuccess = true,
        unanswered = false;
}