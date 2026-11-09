#include <stdio.h>
#include <vga.h>
#include <swap.h>

unsigned int utoa(unsigned int number, char *buf, unsigned int bufsz, unsigned int base, const char *digits)
{
  unsigned int i = 0;
  unsigned int j;
  char tmp;

  /* Check invalid arguments */
  if (buf == NULL || digits == NULL || bufsz <= 1 || base <= 1) {
    if (buf != NULL && bufsz > 0) buf[0] = '\0';
    return 0;
  }

  /* Special case: number == 0 */
  if (number == 0) {
    if (bufsz < 2) {
      buf[0] = '\0';
      return 0;
    }

    buf[0] = digits[0];
    buf[1] = '\0';
    return 1;
  }

  /* Convert number: digits are produced in reverse order */
  while (number > 0) {

    /* Check buffer overflow (+1 for '\0') */
    if (i + 1 >= bufsz) {
      buf[0] = '\0';
      return 0;
    }

    buf[i] = digits[number % base];
    number /= base;
    i++;
  }

  /* Reverse the string */
  for (j = 0; j < i / 2; j++) {
    tmp = buf[j];
    buf[j] = buf[i - 1 - j];
    buf[i - 1 - j] = tmp;
  }

  /* NUL terminator */
  buf[i] = '\0';

  return i;
}

unsigned int scanf_uint(void)
{
  unsigned int number = 0;
  unsigned int digit_count = 0;
  unsigned int has_digit = 0;
  char c;

  while (1) {

    c = getchar();

    /* Enter */
    if (c == '\r' || c == '\n') {

      /* Ignore leftover \r or \n */
      if (!has_digit) {
        continue;
      }

      printf("\n");
      break;
    }

    /* Backspace / Delete */
    if (c == '\b' || c == 127) {
      if (digit_count > 0) {
        number /= 10;
        digit_count--;
        printf("\b \b");
      }
      continue;
    }

    /* Digit 0-9 */
    if (c >= '0' && c <= '9') {

      printf("%c", c);

      number = number * 10 + (c - '0');
      has_digit = 1;
      digit_count++;
    }
  }

  return number;
}

int main(void)
{
    const char *vigesimal_digits = "0123456789ABCDEFGHIJ";
    char buf[10];
    unsigned int number;

    printf("Utoa : Base Vigesimal.\n");

    while (1) {
      printf("Enter a number : ");

      number = scanf_uint();

      utoa(number, buf, sizeof(buf), 20, vigesimal_digits);

      printf("Result : %s\n", buf);

      asm volatile ("l.nios_rrr r0,%[in1],r0,0x6"::[in1]"r"(100000)); //wait
    }

    return 0;
}
