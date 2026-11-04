package com.nguyentuanminh.e_app.repository;

import com.nguyentuanminh.e_app.domain.DeckGift;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

public interface DeckGiftRepository extends JpaRepository<DeckGift, Long> {

    List<DeckGift> findByRecipientIdAndStatusOrderByCreatedAtDesc(Long recipientId, DeckGift.Status status);

    Optional<DeckGift> findByTopicIdAndRecipientIdAndStatus(Long topicId, Long recipientId, DeckGift.Status status);

    @Transactional
    void deleteByTopicId(Long topicId);
}
