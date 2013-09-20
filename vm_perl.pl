#! usr/local/bin/perl

################################################################################
#                  Batalha de Robos - Parte 1 - Maquina Virtual
#                           
#                           Pedro Bruel - 7143336
#
#   Este programa implementa uma maquina virtual capaz de interpretar
#   comandos do usuario ou gerar "bytecode" para um programa ja escrito.
#
#   Sua sintaxe e funcionalidades foram implementadas conforme especificacoes
#   do enunciado. Pontos nao especificados no enunciado foram implementados
#   da maneira descrita na documentacao.
#
#   Caso seja passado um arquivo texto para o programa, ele tentara "compilar"
#   e executar o programa escrito, informando mensagens de erro de execucao
#   ou compilacao conforme necessario.
#
#   Exemplos:
#
#   Modo compilacao e execucao:
#
#       $ perl ep1_vm.pl seu_programa
#
#   Modo interpretador:
#
#       $ perl ep1_vm.pl
#
################################################################################

#
#   Inicio das subrotinas correspondentes as
#   instrucoes implementadas.
#
sub vm_push
{
    push ( @program_memory_stack, $_[ 0 ] );
    return 0;
}
sub vm_pop_print
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> PRN (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $value = pop @program_memory_stack;
    print "<Stack> PRN popped: \"$value\".\n";
    return 0;
}
sub vm_pop
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> POP (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    pop @program_memory_stack;
    return 0;
}
sub vm_end
{
    undef @vm_memory;
    undef @program_instructions;
    undef @program_memory_stack;
    $instruction_pointer = 0;
    $program_lines = 0;
    if ( $error )
    {
        print "[Exit Status $error: Errors Occurred]\n";
        print "<End of Program>\n";
        print "-" x 80 . "\n";
        return -1;
    }
    $error = 0;
    print "<End of Program>\n";
    print "-" x 80 . "\n";
    return 0;
}
sub vm_dup
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> DUP (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $stack_top = $program_memory_stack[ -1 ];
    push ( @program_memory_stack, $stack_top );
    return 0;
}
#
#   Inicio das instrucoes de
#   operacoes aritmeticas:
#
sub vm_add
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> ADD (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $first_number = pop @program_memory_stack;
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> ADD (around line " . ( $instruction_pointer + 1 ) . "): Not enough numbers on stack!\n";
        return -1;
    }
    else
    {
        $second_number = pop @program_memory_stack;
        push ( @program_memory_stack, $first_number + $second_number );
        return 0;
    }
}
sub vm_sub
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> SUB (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $first_number = pop @program_memory_stack;
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> SUB (around line " . ( $instruction_pointer + 1 ) . "): Not enough numbers on stack!\n";
        return -1;
    }
    else
    {
        $second_number = pop @program_memory_stack;
        push ( @program_memory_stack, $second_number - $first_number );
        return 0;
    }
}
sub vm_mul
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> MUL (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $first_number = pop @program_memory_stack;
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> MUL (around line " . ( $instruction_pointer + 1 ) . "): Not enough numbers on stack!\n";
        return -1;
    }
    else
    {
        $second_number = pop @program_memory_stack;
        push ( @program_memory_stack, $second_number * $first_number );
        return 0;
    }
}
sub vm_div
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> DIV (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $first_number = pop @program_memory_stack;
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> DIV (around line " . ( $instruction_pointer + 1 ) . "): Not enough numbers on stack!\n";
        return -1;
    }
    elsif ( $first_number == 0 )
    {
        print STDERR "<Math Error> DIV (around line " . ( $instruction_pointer + 1 ) . "): Division by zero!\n";
        return -1;
    }
    else
    {
        $second_number = pop @program_memory_stack;
        push ( @program_memory_stack, $second_number / $first_number );
        return 0;
    }
}
#
#   Fim das instrucoes de 
#   operacoes aritmeticas.
#
#
#   Instrucoes de manipulacao
#   de memoria:
#
sub vm_sto
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> STO (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $stack_top = pop @program_memory_stack;
    $vm_memory[ $_[ 0 ] ] = $stack_top;
    return 0;
}
sub vm_rcl
{
    if ( !defined $vm_memory[ $_[ 0 ] ] )
    {
        print STDERR "<Runtime Error> RCL (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    push ( @program_memory_stack, $vm_memory[ $_[ 0 ] ] );
    return 0;
}
#
#   Fim das instrucoes de
#   manipulacao de memoria.
#
#   Instrucoes de laco:
#
sub vm_jmp
{
    if ( !exists $labels{ uc $_[ 0 ] } )
    {
        print STDERR "<Runtime Error> JMP (around line " . ( $instruction_pointer + 1 ) . ", label \"$_[ 0 ]\"): No such label!\n";
        return -1;
    }
    $instruction_pointer = $labels{ uc $_[ 0 ] };
    return 0;
}
sub vm_jit
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> JIT (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $top_value = pop @program_memory_stack;
    if ( $top_value )
    {
        return vm_jmp ( $_[ 0 ] );
    }
    $instruction_pointer += 1;
    return 0;
}
sub vm_jif
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> JIF (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $top_value = pop @program_memory_stack;
    if ( !$top_value )
    {
        return vm_jmp ( $_[ 0 ] );
    }
    $instruction_pointer += 1;
    return 0;
}
#
#   Fim das instrucoes de laco.
#
#   Instrucoes de comparacao:
#
sub vm_eq
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> EQ (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $first_number = pop @program_memory_stack;
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> EQ (around line " . ( $instruction_pointer + 1 ) . "): Not enough numbers on stack!\n";
        return -1;
    }
    else
    {
        $second_number = pop @program_memory_stack;
        if ( $first_number == $second_number )
        {
            push ( @program_memory_stack, 1 );
        }
        else
        {
            push ( @program_memory_stack, 0 );
        }
        return 0;
    }
}
sub vm_ne
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> NE (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $first_number = pop @program_memory_stack;
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> NE (around line " . ( $instruction_pointer + 1 ) . "): Not enough numbers on stack!\n";
        return -1;
    }
    else
    {
        $second_number = pop @program_memory_stack;
        if ( $first_number != $second_number )
        {
            push ( @program_memory_stack, 1 );
        }
        else
        {
            push ( @program_memory_stack, 0 );
        }
        return 0;
    }
}
sub vm_gt
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> GT (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $first_number = pop @program_memory_stack;
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> GT (around line " . ( $instruction_pointer + 1 ) . "): Not enough numbers on stack!\n";
        return -1;
    }
    else
    {
        $second_number = pop @program_memory_stack;
        if ( $first_number < $second_number )
        {
            push ( @program_memory_stack, 1 );
        }
        else
        {
            push ( @program_memory_stack, 0 );
        }
        return 0;
    }
}
sub vm_ge
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> GE (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $first_number = pop @program_memory_stack;
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> GE (around line " . ( $instruction_pointer + 1 ) . "): Not enough numbers on stack!\n";
        return -1;
    }
    else
    {
        $second_number = pop @program_memory_stack;
        if ( $first_number <= $second_number )
        {
            push ( @program_memory_stack, 1 );
        }
        else
        {
            push ( @program_memory_stack, 0 );
        }
        return 0;
    }
}
sub vm_lt
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> LT (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $first_number = pop @program_memory_stack;
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> LT (around line " . ( $instruction_pointer + 1 ) . "): Not enough numbers on stack!\n";
        return -1;
    }
    else
    {
        $second_number = pop @program_memory_stack;
        if ( $first_number > $second_number )
        {
            push ( @program_memory_stack, 1 );
        }
        else
        {
            push ( @program_memory_stack, 0 );
        }
        return 0;
    }
}
sub vm_le
{
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> LE (around line " . ( $instruction_pointer + 1 ) . "): Empty Memory!\n";
        return -1;
    }
    $first_number = pop @program_memory_stack;
    if ( !@program_memory_stack )
    {
        print STDERR "<Runtime Error> LE (around line " . ( $instruction_pointer + 1 ) . "): Not enough numbers on stack!\n";
        return -1;
    }
    else
    {
        $second_number = pop @program_memory_stack;
        if ( $first_number >= $second_number )
        {
            push ( @program_memory_stack, 1 );
        }
        else
        {
            push ( @program_memory_stack, 0 );
        }
        return 0;
    }
}
#
#   Fim das instrucoes de comparacao.
#
#   Fim das subrotinas de instrucoes.
#
#   Funcao de inicializacao da Maquina Virtual:
#
sub vm_init
{
    $error = 0;
    $instruction_pointer = 0;
    $program_lines = 0;
    #
    #   Hash com as instrucoes validas
    #   e opcodes respectivos.
    #
    %valid_instructions = (
    #   Recebem argumentos;
        'PUSH'  =>       1,
        'JMP'   =>       2,
        'JIT'   =>       3,
        'JIF'   =>       4,
        'STO'   =>       5,
        'RCL'   =>       6,
    #   Nao recebem argumentos:
        'END'   =>       7,
        'PRN'   =>       8,
        'ADD'   =>       9,
        'MUL'   =>      10,
        'DIV'   =>      11,
        'POP'   =>      12,
        'DUP'   =>      13,
        'SUB'   =>      14,
        'EQ'    =>      15,
        'GT'    =>      16,
        'GE'    =>      17,
        'LT'    =>      18,
        'LE'    =>      19,
        'NE'    =>      20,
    );
    #
    #   Determinando modo de execucao
    #   baseado nos parametros, ou falta
    #   deles.
    #
    print "-" x 80 . "\n";
    print " LabProg II - Perl VM\n";
    if ( @ARGV )
    {
        $interpreter = 0;
        print "-" x 80 . "\n";
        print "<Compilation Started: \"$ARGV[ 0 ]\">\n";
    }
    else
    {
        $interpreter = 1;
        print " <Interpreter Mode>

    help:
                      
        1) Set of valid lines: [label:] [instruction [argument]] [#comments]
        2) []'s denote optional components. Spaces are required.
        #) This is a comment line.
        3) A set of instructions requires a terminating END.
        4) Valid instructions are listed in documentation.
        5) Ctrl+C: Exit.
        \n";
        print "-" x 80 . "\n";
    }
}
#
#   Inicio do codigo para o montador,
#   que recebera um conjunto de instrucoes
#   e gerara o vetor de execucao para o
#   programa especificado pelo usuario.
#
#   Caso receba um arquivo, o programa
#   ira "compilar" e tentar executar as
#   instrucoes.
#
#   Caso nao receba nada, o programa
#   tentara interpretar os comandos do 
#   usuario.
#
sub vm_build_program
{
    if ( $interpreter )
    {
        print "(" . ( $program_lines + 1 ) . ")> ";
    }
    while ( <> )
    {
        #
        #   Associando "labels" a linhas do programa.
        #
        @vm_instruction = split ' ';
        if ( $vm_instruction[ 0 ] =~ /^( |\t)*#(.*)/ or $vm_instruction[ 0 ] =~ /^( |\t)*$/ )
        {
            if ( $interpreter )
            {
                print "(" . ( $program_lines + 1 ) . ")> ";
            }
            next;
        }
        elsif ( $vm_instruction[ 0 ] =~ /^(.+):$/ )
        {
            chop $vm_instruction[ 0 ];
            printf "<Compiler> Binding: (label=\"$vm_instruction[ 0 ]\", around_line=" . ( $program_lines + 1 ) . ")\n";
            $labels{ uc $vm_instruction[ 0 ] } = $program_lines;
            shift @vm_instruction;
            if ( !@vm_instruction or $vm_instruction[ 0 ] =~ /^( |\t)*#(.*)/ )
            {
                if ( $interpreter )
                {
                    print "(" . ( $program_lines + 1 ) . ")> ";
                }
                next;
            }
        }
        #
        #   Checagem de erros de sintaxe
        #   e tratamento de comentarios.
        #
        #
        if ( !exists $valid_instructions{ uc $vm_instruction[ 0 ] } and $vm_instruction[ 0 ] !~ /^( |\t)*#(.*)/ )
        {
            print STDERR "<Syntax Error> \"$vm_instruction[ 0 ]\" (around line " . ( $program_lines + 1 ) . "): No such instruction!\n";
            return -1;
        }
        elsif ( $valid_instructions{ uc $vm_instruction[ 0 ] } < $valid_instructions{ "END" } )
        {
            if ( !defined $vm_instruction[ 1 ] or ( defined $vm_instruction[ 2 ] and $vm_instruction[ 2 ] !~ /^( |\t)*#(.*)/ ) )
            {
                print STDERR "<Syntax Error> \"$vm_instruction[ 0 ]\" (around line " . ( $program_lines + 1 ) . "): Receives one argument!\n";
                return -1;
            }
        }
        elsif ( defined $vm_instruction[ 1 ] and $vm_instruction[ 1 ] !~ /^( |\t)*#(.*)/ )
        {
            print STDERR "<Syntax Error> \"$vm_instruction[ 0 ]\" (around line " . ( $program_lines + 1 ) . "): Wrong number of arguments!\n";
            return -1;
        }
        #
        #   Construcao do vetor de programa.
        #
        @instruction_copy = @vm_instruction;
        #
        #   Traduz instrucoes em opcodes.
        #
        $opcode = $valid_instructions{ uc shift @instruction_copy };
        unshift @instruction_copy, $opcode;
        push @program_instructions, [ @instruction_copy ];
        $program_lines += 1;
        if ( $opcode ==  $valid_instructions{ "END" } )
        {
            last;
        }
        if ( $interpreter )
        {
            print "(" . ( $program_lines + 1 ) . ")> ";
        }
    }
    if ( !$interpreter )
    {
        print "<Compilation Ended> No Errors.\n";
        print "-" x 80 . "\n";
    }
    return 0;
}
#
#   Executor do vetor programa.
#
sub vm_run
{
    print "<Starting Execution>\n";
    while ( $instruction_pointer < $program_lines )
    {
        $current_instruction = $program_instructions[ $instruction_pointer ][ 0 ];
        $current_argument = $program_instructions[ $instruction_pointer ][ 1 ];
        if ( $current_instruction == $valid_instructions{ "END" } )
        {
            return vm_end;
        }
        elsif ( $current_instruction == $valid_instructions{ "JMP" } )
        {
            $exit_status = vm_jmp ( $current_argument );
        }
        elsif ( $current_instruction == $valid_instructions{ "JIF" } )
        {
            $exit_status = vm_jif ( $current_argument );
        }
        elsif ( $current_instruction == $valid_instructions{ "JIT" } )
        {
            $exit_status = vm_jit ( $current_argument );
        }
        elsif ( $current_instruction == $valid_instructions{ "PUSH" } )    
        {
            $exit_status = vm_push ( $current_argument );
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "PRN" }  )
        {        
            $exit_status = vm_pop_print;
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "POP" }  )
        {        
            $exit_status = vm_pop;
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "ADD" }  )
        {
            $exit_status = vm_add;
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "STO" }  )
        {
            $exit_status = vm_sto ( $current_argument );
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "RCL" }  )
        {
            $exit_status = vm_rcl ( $current_argument );
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "EQ" }  )
        {
            $exit_status = vm_eq;
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "NE" }  )
        {
            $exit_status = vm_ne;
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "GT" }  )
        {
            $exit_status = vm_gt;
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "GE" }  )
        {
            $exit_status = vm_ge;
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "LT" }  )
        {
            $exit_status = vm_lt;
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "LE" }  )
        {
            $exit_status = vm_le;
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "SUB" } )
        {
            $exit_status = vm_sub;
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "DUP" } )
        {
            $exit_status = vm_dup;
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "MUL" } )
        {
            $exit_status = vm_mul;
            $instruction_pointer += 1;
        }
        elsif ( $current_instruction == $valid_instructions{ "DIV" } )
        {
            $exit_status = vm_div;
            $instruction_pointer += 1;
        }
        if ( $exit_status )
        {
            print "<Fatal Error> Check console!\n";
            $error = -1;
            return vm_end;
        }
    }
}
#
#   Fim das definicoes de subrotinas.
#
#   Aqui, verifica-se o modo de operacao,
#   e coordena-se a compilacao e execucao
#   do codigo passado pelo usuario,
#   seja por um arquivo ou teclado.
#
#   Procurei fazer com que o interpretador
#   seja "bonzinho" com o usuario, tentando
#   se recuperar de erros de compilacao ou
#   execucao, isto e', nao "morrer" apos um
#   comando malformado.
#
#   Erros encontrados na compilacao ou execucao
#   de programas malformados, fornecidos em arquivos 
#   de texto, sao fatais.
#
vm_init;
if ( !$interpreter )
{
    $error_status = vm_build_program;
    $error_status = vm_run;
}
else
{
    #
    #   Loop do interpretador.
    #
    #   Por simplicidade, o programa
    #   exige um Ctrl+C para terminar.
    #
    $running = 1;
    while ( $running )
    {
        $error_status = vm_build_program;
        while ( $error_status )
        {
            vm_end;
            $error_status = vm_build_program;
        }
        $error_status = vm_run;
    }
}
