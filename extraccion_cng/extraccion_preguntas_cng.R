# Instalar los paquetes si no cuentas con ellos
# install.packages(c("readxl", "writexl", "dplyr", "purrr", "stringr"))

library(readxl)
library(writexl)
library(dplyr)
library(purrr)
library(stringr)

# 1. Abrir ventana emergente para seleccionar el archivo de origen
cat("Por favor, selecciona el archivo Excel de origen en la ventana emergente...\n")

# file.choose() abre la ventana. Usamos un tryCatch por si el usuario cancela (cierra la ventana)
ruta_archivo <- tryCatch(
  file.choose(),
  error = function(e) {
    stop("No se seleccionó ningún archivo. Proceso cancelado.", call. = FALSE)
  }
)

cat("Archivo seleccionado:", ruta_archivo, "\nProcesando...\n")

# 2. Obtener los nombres de todas las pestañas (hojas) del Excel
hojas <- excel_sheets(ruta_archivo)

# 3. Función para procesar cada hoja de manera individual
extraer_columna_a <- function(hoja) {
  
  # Leer SOLAMENTE la Columna A como texto para conservar el formato "1.1.-"
  datos <- suppressMessages(
    read_excel(ruta_archivo, sheet = hoja, range = cell_cols("A"), 
               col_names = FALSE, col_types = "text")
  )
  
  # Si la hoja está completamente vacía, regresamos un tibble nulo
  if(nrow(datos) == 0) return(tibble())
  
  datos |>
    rename(Pregunta = 1) |>
    filter(!is.na(Pregunta)) |>
    mutate(Pregunta = str_trim(Pregunta)) |>
    # Filtrar celdas que empiezan con número (ej. "1", "1.1.-") o que sean un guion "-"
    filter(str_detect(Pregunta, "^\\d|^-$")) |>
    # Crear la columna con el nombre de la pestaña actual
    mutate(Estructura = hoja) |>
    # Ordenar las columnas
    select(Estructura, Pregunta)
}

# 4. Iterar sobre todas las hojas y unirlas
df_final <- map_dfr(hojas, extraer_columna_a)

# 5. Definir ruta de salida (se guarda en la misma carpeta que el archivo original)
# Extraemos el directorio del archivo seleccionado usando dirname()
directorio_origen <- dirname(ruta_archivo)
ruta_salida <- file.path(directorio_origen, "Resumen_Estructura_Preguntas.xlsx")

# 6. Generar el nuevo archivo Excel
write_xlsx(df_final, ruta_salida)

cat("¡Proceso terminado con éxito!\n")
cat("Se extrajeron", nrow(df_final), "preguntas.\n")
cat("El archivo fue guardado en:\n", ruta_salida, "\n")