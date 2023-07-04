/// Returns a bool depending on [bit]: false if it's 0, true otherwise
bool bitToBool(int bit) {
  if (bit == 0) {
    return false;
  }
  return true;
}

/// Returns an int depending on [bit]: 0 if it's false, 1 otherwise
int boolToBit(bool bit) {
  if (bit == false) {
    return 0;
  }
  return 1;
}
