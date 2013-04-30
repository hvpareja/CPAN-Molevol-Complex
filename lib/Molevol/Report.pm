package Molevol::Report;
use Bio::Structure::Model;
use Bio::Structure::IO::pdb;
use Number::FormatEng qw(:all);
use Data::Dumper;

sub get_gc{
    
    my ($self, $gc);
    my @genetic_codes = ("Standar",
                         "Vertebrate mitochondrial"); # Incompleted
    if($gc > scalar(@genetic_codes)){ return "unknown" }
    return $genetic_codes[$gc];
    
}

sub input_information{
    
    my ($self,@data) = @_;
    
    my $pdb           = $data[0];
    my $contact       = $data[1];
    my $aln_file      = $data[2];
    my $subunit       = $data[3];
    my $genetic_code  = $data[4];
    my $spec_chains   = $data[5];
    my $pth           = $data[6];
    my $sth           = $data[7];
    my $msth          = $data[8];
    my $input_format  = $data[9];
    my $output_format = $data[10];
    my $ocontact      = $data[11];
    
    my $string_report =
    
    "
    <h3>1. Input information:</h3>
    <table class='table' id='input_info'>
        <tr class='head'>
            <td align='center'><b>Input files</b></td>
        </tr>
        <tr>
            <td>Input PDB file</td>
            <td>$pdb</td>
        </tr>
        <tr>
            <td>Input contact file</td>
            <td>$contact</td>
        </tr> 
        <tr>
            <td>Alignment file</td>
            <td>$aln_file</td>
        </tr>
        <tr class='head'>
            <td align='center'><b>Params</b></td>
        </tr>
        <tr>
            <td>Subunit</td>
            <td>$subunit</td>
        </tr>
        <tr>
            <td>Genetic code</td>
            <td>".get_gc($genetic_code)."</td>
        </tr>
        <tr>
            <td>Contact with</td>
            <td>$spec_chains</td>
        </tr>
        <tr>
            <td>Proximity threshold</td>
            <td>$pth</td>
        </tr>
        <tr>
            <td>Surface threshold</td>
            <td>$sth</td>
        </tr>
        <tr>
            <td width='200px'>Margin for surf. threshold</td>
            <td>$msth</td>
        </tr>
        <tr>
            <td>Input alignment format</td>
            <td>$input_format</td>
        </tr>
        <tr>
            <td>Output alignments format</td>
            <td>$output_format</td>
        </tr>
        <tr>
            <td>Output contact file</td>
            <td>$ocontact</td>
        </tr>
    </table>    
    ";
    
    return $string_report;
    
}

sub struct_information{
    
    my $struct_report;
    my ($self, $pdb,$raw_table, $chain, $ocontact) = @_;
    
    my @raw_table = @$raw_table;
    my @chains_array;
    my $chains_string;
    my $total_residues;
    my $raw_table_string;
    
    
    if($pdb ne "-"){
        my $pdb_obj = Bio::Structure::IO->new(-file => $pdb,
                                            -format => 'PDB')
                                 or die "\nInvalid pdb file.\n";        
    
        # For each structure in pdb file (just one)
        my $struc = $pdb_obj->next_structure;
        
        # Models
        my @models = $struc->get_models;
        foreach my $model (@models){
          
          my @chains_model = $struc->get_chains($model);
          # Store all chains from all models in the same array
          push(@chains_array, @chains_model);
          
        }
    
        # Store all chains ids into a string
        foreach my $item (@chains_array){
            
            if($item->id eq $chain){
                $chains_string = $chains_string." <font size='8'><b>".$item->id."</b></font>";
                $total_residues = scalar($struc->get_residues($item))." residues";
            }
            else{
                $chains_string = $chains_string." ".$item->id;
            }
        }
    }else{
        $chains_string = "<i>PDB required</i>";
        $total_residues = "<i>PDB required</i>";
    }
    
    # Raw table
    $raw_table_string = "<table>";
    foreach my $line (@raw_table){
     
     my @column = split(/\t/,$line);
     my $tr;
     foreach $data (@column){
        
        $tr = $tr."<td align='center' width='100'>$data</td>";
        
     }
     $raw_table_string = $raw_table_string."<tr>".$tr."</tr>";   
        
    }    
    $raw_table_string = $raw_table_string."</table>";     
        
    $struct_report =
    
    "
    <h3>2. Structural info</h3>
    <h4>2.1. Subunits:</h4> $chains_string<br>
    <h4>2.2. Chain length:</h4> $total_residues<br>
    <h4>2.3. Molecular interactions report (saved at $ocontact):</h4><br>
    $raw_table_string
    "
    
    ;
    
    return $struct_report;
}

sub codon_lists{
    
    my $list_string;
    my ($self,$sets) = @_;
    %sets = %$sets;
    
    $list_string = "<h3>3. Categories of codons</h3>";
    $list_string = $list_string."<table><tr align='center'>
                                        <td><b>Category name</b>
                                        </td>
                                        <td><b>Codon numbers</b>
                                        </td>
                                        </tr>";
    foreach my $key (keys %sets){
        
        my $numbers;
        # Concatenate numbers
        foreach my $number (@{$sets{$key}}){
            $numbers = $numbers." ".$number.",";
        }
        
        chop($numbers);
        
        $list_string = $list_string.
                "<tr>
                    <td width='250px'>$key</td>
                    <td>$numbers</td>
                </tr>";
        
    }
    
    $list_string = $list_string."</table>";
    
    
    return $list_string;
    
}

sub sub_alignments{
    
    my $string_aln_report;
    my ($self, $oformat, $alns) = @_;
    %alns = %$alns;
    
    
    foreach my $aln (keys %alns){
        
        # Bioperl only export alignments to filehandles ...
        # so I need work with files to build the report as my wishes.
       open OUT, ">p";
       my $string_aln;
       my $out = Bio::AlignIO->new(-fh => \*OUT,
                                   -format => $oformat);
       $out->write_aln($alns{$aln});
       
       close OUT;
       open IN, "p";
       
       while (<IN>) {
        $string_aln = $string_aln.$_."<br>";
       }
       close IN;
       
       $string_aln_report = $string_aln_report.
                            "<h4>Alignment for: $aln</h4>".
                            "".
                            $string_aln
                            ."";
       
    }
    system("rm p");
    
    $string_aln_report =
    "
    <h3>4. Sub-alignments</h4>
    "
    .$string_aln_report
    ;
    
    return $string_aln_report;
    
}

sub yang_report{
    
    # Just Yang table
    my ($self, $evol_data) = @_;
    my %evol_data = %$evol_data;
    my $yang_string;
    $yang_string = "<h3>5. Raw report for Yang's analisys</h3>";
    foreach my $key (keys %evol_data){
        
        my $table = $evol_data{$key}{yang_table};
        
        my $table_str = "<table>";
        foreach my $line (split (/\n/,$table)){
            
            if(!grep(/^--/,$line)){
            
                $table_str = $table_str."<tr>";
                foreach my $cell (split (/\t/,$line)){
                    
                    $table_str = $table_str."<td align='center'>$cell</td>";
                    
                }
                $table_str = $table_str."</tr>";
            }
        }
        
        $table_str = $table_str."</table>";
        
        $yang_string = $yang_string."<h4>Results for: $key</h4>";
        $yang_string = $yang_string.$table_str;
        
        
    }
    
    
    return $yang_string;
    
}

sub stats1{
    
    my ($self,$results) = @_;
    my %results = %$results;
    my $stats_str = "<h3>6. Statistics</h3>";
    
    $stats_str = $stats_str."<table>";
    $stats_str = $stats_str."<tr align='center'>";
    $stats_str = $stats_str."<td><b>Category</b></td>";
    $stats_str = $stats_str."<td><b>kdNx</b></td>";
    $stats_str = $stats_str."<td><b>kdNy</b></td>";
    $stats_str = $stats_str."<td><b>kdNx Variance</b></td>";
    $stats_str = $stats_str."<td><b>kdNy Variance</b></td>";
    $stats_str = $stats_str."<td><b>Correlation coef.</b></td>";
    $stats_str = $stats_str."<td><b>Cocient</b></td>";
    $stats_str = $stats_str."<td><b>Cocient Variance</b></td>";
    $stats_str = $stats_str."<td><b>p Value</b></td>";
    $stats_str = $stats_str."</tr>";
    
    foreach my $res (keys %results){
        
        $stats_str = $stats_str."<tr align='center'>";
        $stats_str = $stats_str."<td>$res</td>";
        $stats_str = $stats_str."<td>".$results{$res}{xsum}."</td>";
        $stats_str = $stats_str."<td>".$results{$res}{ysum}."</td>";
        $stats_str = $stats_str."<td>".format_eng($results{$res}{x_var_sum})."</td>";
        $stats_str = $stats_str."<td>".format_eng($results{$res}{y_var_sum})."</td>";
        $stats_str = $stats_str."<td>".$results{$res}{correlation}."</td>";
        $stats_str = $stats_str."<td>".$results{$res}{cocient}."</td>";
        $stats_str = $stats_str."<td>".format_eng($results{$res}{cocient_variance})."</td>";
        $stats_str = $stats_str."<td>".format_eng($results{$res}{p_value})."</td>";
        $stats_str = $stats_str."</tr>";
        
    }
    
    return $stats_str;
    
}

1;