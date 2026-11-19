
<?php
header('Content-Type: application/json');

$con = new mysqli("localhost", "root", "", "sistema_trufas");

$id = (int) ($_POST['produtor_id'] ?? 0);
$quantidade = (int) ($_POST['quantidade'] ?? 0);
$valor = (float) ($_POST['valor'] ?? 0);

if ($id <= 0 || $quantidade <= 0 || $valor <= 0) {
    echo json_encode(["mensagem" => "Dados inválidos"]);
    exit;
}

$sql = $con->prepare(
    "INSERT INTO producoes
    (produtor_id, quantidade, estoque, valor_unitario)
    SELECT id, ?, ?, ? FROM usuarios
    WHERE id = ? AND perfil = 'produtor'"
);

$sql->bind_param("iidi", $quantidade, $quantidade, $valor, $id);

$sql->execute();

if ($sql->affected_rows > 0) {
    echo json_encode(["mensagem" => "Produção cadastrada"]);
} else {
    echo json_encode(["mensagem" => "Erro ao cadastrar"]);
}

$con->close();
?>
