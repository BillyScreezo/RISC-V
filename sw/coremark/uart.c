#define UART_BASE	0x20000000
#define UART_CTRL   *((volatile int*)(UART_BASE + 0x00))
#define UART_TXD    *((volatile int*)(UART_BASE + 0x04))

void uart_send_char(char c)
{
	while (UART_CTRL != 1) {
		// wait UART ready
	}

	UART_TXD = c;
}
