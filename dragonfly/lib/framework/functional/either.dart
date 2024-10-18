abstract interface class Either<Error, Response> {
  Response right();
  Error left();
}
