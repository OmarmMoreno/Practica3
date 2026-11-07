defmodule Procesos do
    @moduledoc "Procesos participantes: proponen un valor y pueden fallar (10 %)."

    @doc "Etapa 1: genera y envía una propuesta al líder, o falla antes de enviarla."
    def envia_mensaje(lider_pid) do
    n = Enum.random(1..1000)
    mi_pid = self()

    # El proceso falla cuando el número aleatorio entre 1 y 10 es 3 (10 %)

    if Enum.random(1..10) == 3 do
        IO.puts("El proceso #{inspect(mi_pid)} propone #{(n)}, antes de fallar")
        send(lider_pid, {:propuesta_fallida, mi_pid})
    else
        IO.puts("El proceso #{inspect(mi_pid)} propone #{(n)}, 1 veces")
        send(lider_pid, {:propuesta_valida, mi_pid, n})
        espera_decision(lider_pid, n)
    end
    end

     # Etapa 3: espera la decisión del líder (o :abortar si no hay consenso)

    defp espera_decision(lider_pid, n) do
        receive do
            {:decision, acordado} ->
                IO.puts("El proceso #{inspect(self())} propone #{n}, 2 veces")
                send(lider_pid, {:ack, self()})
                espera_operacion(lider_pid, acordado)

            :abortar ->
                :ok
            end
        end

    # Etapa 5: nueva oportunidad de fallo; si no falla, registra el valor

    defp espera_operacion(lider_pid, _acordado) do
        receive do
            {:operar, valor} ->
                if Enum.random(1..10) == 3 do
                    IO.puts("El proceso #{inspect(self())} falla al ejecutar la operacion")
                    send(lider_pid, {:operacion, self(), :fallo})
                else
                    estado = valor
                    IO.puts("El proceso #{inspect(self())} registra el valor #{estado}")
                    send(lider_pid, {:operacion, self(), :ok})
                end
            end
        end
    end

defmodule Lider do

    @moduledoc "Líder: coordina propuestas, quórum, consenso y operación distribuida."

    @doc "Ejecuta la simulación con `n_procesos` participantes."
    def start(n_procesos) do
        IO.puts("------ Iniciando consenso -----------")
        lider_pid = self()
        # Etapa 1: crear participantes
        Enum.each(1..n_procesos, fn _ ->
            spawn(fn -> Procesos.envia_mensaje(lider_pid) end)
        end)

         # Etapa 2: un mensaje por proceso; validas conserva los pids
        mensajes = for _ <- 1..n_procesos, do: recibe()
        validas = for {:propuesta_valida, pid, n} <- mensajes, do: {pid, n}
        valores =   for({:propuesta_valida, _pid, n} <- mensajes, do: n)|> Enum.sort()

        IO.inspect("Estoy esperando mensajes")
        IO.puts("v=#{inspect(valores)}")

        # Etapa 3: quórum Q = N/2 + 1 (N inicial)
        quorum = div(n_procesos, 2) + 1

        if length(valores)< quorum do
            for {pid, _} <- validas, do: send(pid, :abortar)
            IO.puts("------ Resultado del consenso -----------")
            IO.puts("No es posible llegar a un consenso")
        else
            acordado = hd(valores)

        for {pid, _} <- validas, do: send(pid, {:decision, acordado})
        for _ <- validas, do: recibe()

        c = length(validas)

        # Etapa 4: anuncio
        IO.inspect("Estoy esperando mensajes")
        IO.puts("------ Resultado del consenso -----------")
        IO.puts("El total de procesos que participaron es #{n_procesos}")
        IO.puts("El acuerdo es #{acordado}")
        IO.puts("Numero de procesos que terminaron el algoritmo #{c}")



        # Etapa 5: operación distribuida
        IO.puts("------ Ejecucion de la operacion --------")
        for {pid, _} <- validas, do: send(pid, {:operar, acordado})
        resultados = for _ <- validas, do: recibe()

        e = Enum.count(resultados, fn r -> match?({:operacion, _, :ok}, r) end)
        f = Enum.count(resultados, fn r -> match?({:operacion, _, :fallo}, r) end)

        # Etapa 6: resumen final
        IO.puts("----- Resumen final ---------")
        IO.puts("El total de procesos que participaron es #{n_procesos}")
        IO.puts("Numero de procesos que terminaron el algoritmo #{c}")
        IO.puts("Procesos que confirmaron la operación: #{e}")
        IO.puts("Procesos que no completaron la operación: #{f}")
        end
    end
# Espera y devuelve el siguiente mensaje del buzón
defp recibe do
    receive do
      msg -> msg
    end
  end
end
