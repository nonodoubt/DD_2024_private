nextflow.enable.dsl=2

// Устанавливаем путь к файлу образцов
params.samples = file("samples.csv")

// Чтение CSV файла как строк и разбиение на части
Channel
    .fromPath(params.samples)  // Загружаем файл с использованием fromPath
    .splitCsv(header: true)     // Разделяем CSV файл, учитывая заголовок
    .map { row -> 
        [file("test_input/${row.read_1}"), file("test_input/${row.read_2}")]  // Используем относительные пути для fastq файлов
    }
    .set { reads }

// Процесс для выполнения FastQC
process fastqc {
    input:
    path fastq_file

    output:
    path "fastqc_output"

    script:
    """
    mkdir -p fastqc_output
    fastqc ${fastq_file} --outdir fastqc_output
    """
}

// Процесс для выполнения SPAdes
process spades {
    input:
    path fastq_1
    path fastq_2

    output:
    path "spades_output/*"

    script:
    """
    spades.py --pe1-1 ${fastq_1} --pe1-2 ${fastq_2} -o spades_output
    """
}

// Процесс для выполнения Quast
process quast_run {
    input:
    path contigs

    output:
    path "quast_output"

    script:
    """
    quast.py --output-dir quast_output ${contigs}
    """
}

// Процесс для выполнения Prokka
process prokka {
    input:
    path contigs

    output:
    path "prokka_output"

    script:
    """
    prokka --outdir prokka_output --prefix prokka_output ${contigs}
    """
}

// Процесс для выполнения Abricate
process abricate {
    input:
    path contigs

    output:
    path "abricate_output"

    script:
    """
    abricate ${contigs} > abricate_output
    """
}

// Пайплайн для выполнения всех процессов
workflow {
    // Обработка FastQC
    fastqc(reads.map { it[0] })

    // Сборка с помощью SPAdes
    reads_ch1 = reads.map { it[0] }  // Первый файл
    reads_ch2 = reads.map { it[1] }  // Второй файл
    spades(reads_ch1, reads_ch2)

    // Оценка качества сборки с помощью Quast
    spades_output = spades.out  // Результаты сборки SPAdes
    quast_run(spades_output)

    // Аннотация с помощью Prokka
    prokka(spades_output)

    // Сканирование устойчивости с помощью Abricate
    abricate(spades_output)
}
