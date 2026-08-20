#include "gpio.h"

#include <winsock2.h>
#include <windows.h>
#include <stdio.h>
#include <string.h>

#define HTTP_PORT 8080

static int led_state = 0;
static SOCKET server_socket;

/* ---------------------------------------------------------
 * Send HTTP response
 * --------------------------------------------------------- */

static void send_response(
    SOCKET client,
    const char *content_type,
    const char *body
)
{
    char response[4096];

    snprintf(
        response,
        sizeof(response),

        "HTTP/1.1 200 OK\r\n"
        "Content-Type: %s\r\n"
        "Content-Length: %zu\r\n"
        "Connection: close\r\n"
        "\r\n"
        "%s",

        content_type,
        strlen(body),
        body
    );

    send(
        client,
        response,
        (int)strlen(response),
        0
    );
}

/* ---------------------------------------------------------
 * Send main HTML page
 * --------------------------------------------------------- */

static void send_led_page(SOCKET client)
{
    const char *page =
        "<!DOCTYPE html>"
        "<html>"
        "<head>"
        "<meta charset=\"UTF-8\">"
        "<title>Virtual GPIO</title>"

        "<style>"
        "body {"
        "    font-family: Arial;"
        "    text-align: center;"
        "    margin-top: 60px;"
        "}"

        "#led {"
        "    width: 120px;"
        "    height: 120px;"
        "    border-radius: 50%;"
        "    margin: 40px auto;"
        "    background: #333;"
        "}"

        ".on {"
        "    background: #ff3030 !important;"
        "    box-shadow: 0 0 40px #ff3030;"
        "}"

        "</style>"

        "</head>"

        "<body>"

        "<h1>Virtual GPIO</h1>"

        "<div id=\"led\"></div>"

        "<h2 id=\"state\">LED OFF</h2>"

        "<script>"

        "function updateLED() {"

        "    fetch('/state')"
        "        .then(response => response.text())"
        "        .then(state => {"

        "            const led = document.getElementById('led');"
        "            const text = document.getElementById('state');"

        "            if (state === '1') {"
        "                led.classList.add('on');"
        "                text.innerText = 'LED ON';"
        "            }"
        "            else {"
        "                led.classList.remove('on');"
        "                text.innerText = 'LED OFF';"
        "            }"

        "        });"
        "}"

        "updateLED();"

        "setInterval(updateLED, 100);"

        "</script>"

        "</body>"
        "</html>";

    send_response(
        client,
        "text/html",
        page
    );
}

/* ---------------------------------------------------------
 * Send LED state
 * --------------------------------------------------------- */

static void send_led_state(SOCKET client)
{
    const char *state;

    if (led_state)
        state = "1";
    else
        state = "0";

    send_response(
        client,
        "text/plain",
        state
    );
}

/* ---------------------------------------------------------
 * HTTP server thread
 * --------------------------------------------------------- */

static DWORD WINAPI http_server(void *argument)
{
    (void)argument;

    printf("[HTTP] Server thread started.\n");

    while (1)
    {
        SOCKET client = accept(
            server_socket,
            NULL,
            NULL
        );

        if (client == INVALID_SOCKET)
        {
            printf("[HTTP] Client connection failed.\n");
            break;
        }

        char request[1024];

        int received = recv(
            client,
            request,
            sizeof(request) - 1,
            0
        );

        if (received <= 0)
        {
            closesocket(client);
            continue;
        }

        request[received] = '\0';

        /*
         * Very small HTTP request parser.
         */

        if (strncmp(request, "GET /state", 10) == 0)
        {
            send_led_state(client);
        }
        else
        {
            send_led_page(client);
        }

        closesocket(client);
    }

    return 0;
}

/* ---------------------------------------------------------
 * Virtual GPIO initialization
 * --------------------------------------------------------- */

void gpio_init(void)
{
    printf("[GPIO] Initializing virtual GPIO...\n");

    WSADATA wsa;

    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0)
    {
        printf("[ERROR] WSAStartup failed.\n");
        return;
    }

    led_state = 0;

    server_socket = socket(
        AF_INET,
        SOCK_STREAM,
        IPPROTO_TCP
    );

    if (server_socket == INVALID_SOCKET)
    {
        printf("[ERROR] Socket creation failed.\n");

        WSACleanup();

        return;
    }

    struct sockaddr_in address;

    memset(
        &address,
        0,
        sizeof(address)
    );

    address.sin_family = AF_INET;

    /*
     * Listen on all local IPv4 interfaces.
     *
     * This allows:
     *
     * http://localhost:8080/
     * http://127.0.0.1:8080/
     */

    address.sin_addr.s_addr = htonl(INADDR_ANY);

    address.sin_port = htons(HTTP_PORT);

    if (bind(
        server_socket,
        (struct sockaddr *)&address,
        sizeof(address)
    ) == SOCKET_ERROR)
    {
        printf("[ERROR] Failed to bind port %d.\n", HTTP_PORT);

        closesocket(server_socket);

        WSACleanup();

        return;
    }

    if (listen(
        server_socket,
        5
    ) == SOCKET_ERROR)
    {
        printf("[ERROR] Failed to start listening.\n");

        closesocket(server_socket);

        WSACleanup();

        return;
    }

    printf("[HTTP] Web server started.\n");
    printf("[HTTP] Listening on port %d.\n", HTTP_PORT);

    HANDLE thread = CreateThread(
        NULL,
        0,
        http_server,
        NULL,
        0,
        NULL
    );

    if (thread == NULL)
    {
        printf("[ERROR] Failed to create HTTP server thread.\n");

        closesocket(server_socket);

        WSACleanup();

        return;
    }

    CloseHandle(thread);

    printf("[HTTP] Server thread created.\n");

    printf("\n");
    printf("========================================\n");
    printf(" Virtual GPIO is ready\n");
    printf("========================================\n");
    printf("\n");

    printf("Open your browser:\n");
    printf("http://127.0.0.1:8080/\n");
    printf("\n");
}

/* ---------------------------------------------------------
 * Virtual LED
 * --------------------------------------------------------- */

void led_on(void)
{
    led_state = 1;

    //printf("[GPIO] LED ON\n");
}

void led_off(void)
{
    led_state = 0;

    //printf("[GPIO] LED OFF\n");
}