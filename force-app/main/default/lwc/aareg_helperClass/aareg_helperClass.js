export function validateEmail(email) {
  const regExp = /\S+@\S+\.\S+/;
    if (!regExp.test(email) || email === null || email === '') {
      return true;
    } 
    return false;
  }