/*
 * retarget.c
 *
 * Retarget minimal stdio to USART3 (huart3) for console output/input.
 */

#include "main.h"

/* Exported from main.c */
extern UART_HandleTypeDef huart3;

/*
> comment out __io_putchar to avoid conflict from app_main.c

__attribute__((weak)) int __io_putchar(int ch)
{
    uint8_t c = (uint8_t)ch;
    if (HAL_UART_Transmit(&huart3, &c, 1, HAL_MAX_DELAY) == HAL_OK)
    {
        return ch;
    }
    return -1;
}
*/

__attribute__((weak)) int __io_getchar(void)
{
    uint8_t c = 0;
    if (HAL_UART_Receive(&huart3, &c, 1, HAL_MAX_DELAY) == HAL_OK)
    {
        return (int)c;
    }
    return -1;
}
