
<?php
header('Content-Type: application/json; charset=utf-8');

$vendedor = (int) ($_POST['vendedor_id'] ?? 0);
$producao = (int) ($_POST['producao_id'] ?? 0);
$quantidade = (int) ($_POST['quantidade'] ?? 0);

if ($vendedor <= 0 || $producao <= 0 || $quantidade <= 0) {
    echo json_encode(["mensagem" => "Dados inválidos"]);
    exit;
}

try {
    $con = new mysqli("localhost", "root", "", "sistema_trufas");
    $con->begin_transaction();

    $sql = $con->prepare(
        "SELECT id FROM usuarios WHERE id = ? AND perfil = 'vendedor'"
    );
    $sql->bind_param("i", $vendedor);
    $sql->execute();

    if (!$sql->get_result()->fetch_assoc()) {
        $con->rollback();
        echo json_encode(["mensagem" => "Vendedor inválido"]);
        exit;
    }

    $sql = $con->prepare(
        "SELECT estoque, valor_unitario
         FROM producoes WHERE id = ? FOR UPDATE"
    );
    $sql->bind_param("i", $producao);
    $sql->execute();

    $dados = $sql->get_result()->fetch_assoc();

    if (!$dados || $dados['estoque'] < $quantidade) {
        $con->rollback();
        echo json_encode(["mensagem" => "Estoque insuficiente"]);
        exit;
    }

    $total = round(
        $quantidade * $dados['valor_unitario'] * 1.10, 2
    );

    $sql = $con->prepare(
        "UPDATE producoes SET estoque = estoque - ?
         WHERE id = ?"
    );
    $sql->bind_param("ii", $quantidade, $producao);
    $sql->execute();

    $sql = $con->prepare(
        "INSERT INTO compras
         (vendedor_id, producao_id, quantidade, valor_total)
         VALUES (?, ?, ?, ?)"
    );
    $sql->bind_param(
        "iiid", $vendedor, $producao, $quantidade, $total
    );
    $sql->execute();

    $con->commit();

    echo json_encode([
        "mensagem" => "Compra realizada",
        "total" => $total
    ]);

    $con->close();

} catch (Throwable $e) {
    if (isset($con)) {
        $con->rollback();
    }
    echo json_encode(["mensagem" => "Erro ao realizar compra"]);
}
?>
